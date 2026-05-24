locals {
  name_prefix = "docuvault-preprod"
  env         = "preprod"
  az_count    = 2

  # Mirrors dev sizing — preprod is for integration testing, not load
  ec2_instance_type  = "t3.micro"
  rds_instance_class = "db.t3.micro"
  task_cpu           = 256
  task_memory        = 512
  asg_min            = 1
  asg_max            = 2
  asg_desired        = 1
  log_retention_days = 14

  account_id  = data.aws_caller_identity.current.account_id
  ecr_base    = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.name_prefix}"
  webui_image = "${local.ecr_base}-web:${var.webui_image_tag}"
  bff_image   = "${local.ecr_base}-bff:${var.bff_image_tag}"
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source      = "../../modules/vpc"
  name_prefix = local.name_prefix
  vpc_cidr    = "10.1.0.0/16"
  az_count    = local.az_count
}

module "ecr" {
  source      = "../../modules/ecr"
  name_prefix = local.name_prefix
  repositories = [
    "web", "bff", "auth-service", "document-service",
    "processing-service", "search-service", "notification-service"
  ]
  image_retention_count = 5
}

module "sns" {
  source      = "../../modules/sns"
  name_prefix = local.name_prefix
}

module "sqs" {
  source      = "../../modules/sqs"
  name_prefix = local.name_prefix
  processing_visibility_timeout = 300
  sns_processing_topic_arn      = module.sns.processing_events_topic_arn
}

resource "aws_sns_topic_subscription" "processing_to_notification" {
  topic_arn            = module.sns.processing_events_topic_arn
  protocol             = "sqs"
  endpoint             = module.sqs.notification_queue_arn
  raw_message_delivery = true
}

module "alb" {
  source      = "../../modules/alb"
  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id

  public_subnet_ids          = module.vpc.public_subnet_ids
  default_service            = "web"
  acm_certificate_arn        = null
  enable_deletion_protection = false

  services = [
    {
      name              = "bff"
      port              = 3000
      health_check_path = "/health"
      path_patterns     = ["/api/*"]
      priority          = 10
    },
    {
      name              = "web"
      port              = 4000
      health_check_path = "/"
      path_patterns     = ["/*"]
      priority          = 100
    }
  ]
}

module "ecs_cluster" {
  source      = "../../modules/ecs-cluster"
  name_prefix = local.name_prefix

  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb.ecs_tasks_security_group_id]

  instance_type       = local.ec2_instance_type
  associate_public_ip = true
  asg_min             = local.asg_min
  asg_max             = local.asg_max
  asg_desired         = local.asg_desired

  container_insights = false
  log_retention_days = local.log_retention_days
}

module "cognito" {
  source      = "../../modules/cognito"
  name_prefix = local.name_prefix
  callback_urls = ["https://${module.cloudfront.domain_name}/auth/callback"]
  logout_urls   = ["https://${module.cloudfront.domain_name}"]
}

module "dynamodb" {
  source      = "../../modules/dynamodb"
  name_prefix = local.name_prefix
  enable_pitr = false
}

module "s3" {
  source      = "../../modules/s3"
  name_prefix = local.name_prefix
  allowed_origins   = ["https://${module.cloudfront.domain_name}"]
  enable_versioning = false
}

module "rds" {
  source      = "../../modules/rds"
  name_prefix = local.name_prefix

  vpc_id                      = module.vpc.vpc_id
  subnet_ids                  = module.vpc.private_subnet_ids
  ecs_tasks_security_group_id = module.alb.ecs_tasks_security_group_id

  instance_class        = local.rds_instance_class
  allocated_storage     = 20
  max_allocated_storage = 20

  db_name     = "docuvault"
  db_username = "docuvault_admin"
  db_password = var.db_password

  multi_az              = false
  deletion_protection   = false
  skip_final_snapshot   = true
  backup_retention_days = 7
  performance_insights  = false
}

module "lambda" {
  source      = "../../modules/lambda"
  name_prefix = local.name_prefix

  processing_queue_url   = module.sqs.processing_queue_url
  processing_queue_arn   = module.sqs.processing_queue_arn
  documents_bucket_name  = module.s3.documents_bucket_name
  documents_bucket_arn   = module.s3.documents_bucket_arn
  thumbnails_bucket_name = module.s3.thumbnails_bucket_name
  thumbnails_bucket_arn  = module.s3.thumbnails_bucket_arn

  processing_jobs_table_name = module.dynamodb.processing_jobs_table_name
  processing_jobs_table_arn  = module.dynamodb.processing_jobs_table_arn
  log_retention_days         = local.log_retention_days
}

module "cloudfront" {
  source      = "../../modules/cloudfront"
  name_prefix = local.name_prefix
  alb_dns_name                  = module.alb.alb_dns_name
  domain_names                  = []
  acm_certificate_arn_us_east_1 = null
  price_class                   = "PriceClass_200"
}

resource "aws_iam_role" "bff_task" {
  name = "${local.name_prefix}-bff-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role" "webui_task" {
  name = "${local.name_prefix}-webui-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

module "ecs_service_bff" {
  source = "../../modules/ecs-service"

  service_name            = "bff"
  cluster_id              = module.ecs_cluster.cluster_id
  cluster_name            = module.ecs_cluster.cluster_name
  capacity_provider_name  = module.ecs_cluster.capacity_provider_name
  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn           = aws_iam_role.bff_task.arn

  container_image  = local.bff_image
  container_port   = 3000
  task_cpu         = local.task_cpu
  task_memory      = local.task_memory
  desired_count    = 1
  target_group_arn = module.alb.target_group_arns["bff"]

  environment_variables = {
    NODE_ENV                  = "preprod"
    PORT                      = "3000"
    LOG_LEVEL                 = "info"
    AWS_REGION                = var.aws_region
    AUTH_SERVICE_URL          = "http://placeholder-auth:3001"
    DOCUMENT_SERVICE_URL      = "http://placeholder-document:3002"
    PROCESSING_SERVICE_URL    = "http://placeholder-processing:3003"
    SEARCH_SERVICE_URL        = "http://placeholder-search:3004"
    NOTIFICATION_SERVICE_URL  = "http://placeholder-notification:3005"
  }

  log_retention_days = local.log_retention_days
}

module "ecs_service_webui" {
  source = "../../modules/ecs-service"

  service_name            = "web"
  cluster_id              = module.ecs_cluster.cluster_id
  cluster_name            = module.ecs_cluster.cluster_name
  capacity_provider_name  = module.ecs_cluster.capacity_provider_name
  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn           = aws_iam_role.webui_task.arn

  container_image  = local.webui_image
  container_port   = 4000
  task_cpu         = local.task_cpu
  task_memory      = local.task_memory
  desired_count    = 1
  target_group_arn = module.alb.target_group_arns["web"]

  environment_variables = {
    NODE_ENV              = "preprod"
    PORT                  = "4000"
    NEXT_PUBLIC_BFF_URL   = "https://${module.cloudfront.domain_name}"
    NEXT_PUBLIC_S3_BUCKET_URL = "https://${module.s3.documents_bucket_domain}"
  }

  log_retention_days = local.log_retention_days
}

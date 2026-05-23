locals {
  name_prefix = "docuvault-prod"
  env         = "prod"
  az_count    = 2

  # Prod sizing — larger instances, multi-AZ RDS, more headroom
  ec2_instance_type  = "t3.small"
  rds_instance_class = "db.t3.small"
  task_cpu           = 512
  task_memory        = 1024
  asg_min            = 2
  asg_max            = 5
  asg_desired        = 2
  log_retention_days = 30

  account_id  = data.aws_caller_identity.current.account_id
  ecr_base    = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.name_prefix}"
  webui_image = "${local.ecr_base}-web:${var.webui_image_tag}"
  bff_image   = "${local.ecr_base}-bff:${var.bff_image_tag}"
}

data "aws_caller_identity" "current" {}

# ── Networking ────────────────────────────────────────────────────────────

module "vpc" {
  source      = "../../modules/vpc"
  name_prefix = local.name_prefix
  vpc_cidr    = "10.2.0.0/16"
  az_count    = local.az_count
}

# ── Container registry ────────────────────────────────────────────────────

module "ecr" {
  source      = "../../modules/ecr"
  name_prefix = local.name_prefix
  repositories = [
    "web", "bff", "auth-service", "document-service",
    "processing-service", "search-service", "notification-service"
  ]
  image_retention_count = 10
}

# ── Messaging ─────────────────────────────────────────────────────────────

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

# ── Load balancer (HTTPS when cert is provided) ────────────────────────────

module "alb" {
  source      = "../../modules/alb"
  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id

  public_subnet_ids          = module.vpc.public_subnet_ids
  default_service            = "web"
  acm_certificate_arn        = var.acm_certificate_arn
  enable_deletion_protection = true

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

# ── ECS cluster ───────────────────────────────────────────────────────────

module "ecs_cluster" {
  source      = "../../modules/ecs-cluster"
  name_prefix = local.name_prefix

  # In prod ECS tasks stay in public subnets (no NAT Gateway).
  # If budget allows NAT, move to private subnets and set associate_public_ip = false.
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb.ecs_tasks_security_group_id]

  instance_type       = local.ec2_instance_type
  associate_public_ip = true
  asg_min             = local.asg_min
  asg_max             = local.asg_max
  asg_desired         = local.asg_desired

  # Container Insights enabled in prod for full observability
  container_insights = true
  log_retention_days = local.log_retention_days
}

# ── Cognito ───────────────────────────────────────────────────────────────

module "cognito" {
  source      = "../../modules/cognito"
  name_prefix = local.name_prefix

  callback_urls = length(var.domain_names) > 0 ? [
    "https://${var.domain_names[0]}/auth/callback"
    ] : [
    "https://${module.cloudfront.domain_name}/auth/callback"
  ]

  logout_urls = length(var.domain_names) > 0 ? [
    "https://${var.domain_names[0]}"
    ] : [
    "https://${module.cloudfront.domain_name}"
  ]
}

# ── Storage ───────────────────────────────────────────────────────────────

module "dynamodb" {
  source      = "../../modules/dynamodb"
  name_prefix = local.name_prefix
  enable_pitr = true
}

module "s3" {
  source      = "../../modules/s3"
  name_prefix = local.name_prefix

  allowed_origins = length(var.domain_names) > 0 ? [
    "https://${var.domain_names[0]}"
    ] : [
    "https://${module.cloudfront.domain_name}"
  ]

  enable_versioning = true
}

module "rds" {
  source      = "../../modules/rds"
  name_prefix = local.name_prefix

  vpc_id                      = module.vpc.vpc_id
  subnet_ids                  = module.vpc.private_subnet_ids
  ecs_tasks_security_group_id = module.alb.ecs_tasks_security_group_id

  instance_class        = local.rds_instance_class
  allocated_storage     = 20
  max_allocated_storage = 100

  db_name     = "docuvault"
  db_username = "docuvault_admin"
  db_password = var.db_password

  # Multi-AZ gives automatic failover — standby replica in second AZ
  multi_az              = true
  deletion_protection   = true
  skip_final_snapshot   = false
  backup_retention_days = 14
  performance_insights  = true
}

# ── Lambda functions ──────────────────────────────────────────────────────

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

# ── CloudFront ────────────────────────────────────────────────────────────

module "cloudfront" {
  source      = "../../modules/cloudfront"
  name_prefix = local.name_prefix

  alb_dns_name                  = module.alb.alb_dns_name
  domain_names                  = var.domain_names
  acm_certificate_arn_us_east_1 = var.acm_certificate_arn_us_east_1
  price_class                   = "PriceClass_200"
}

# ── IAM task roles ────────────────────────────────────────────────────────

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

# ── ECS service — BFF ─────────────────────────────────────────────────────

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
  desired_count    = local.asg_desired
  target_group_arn = module.alb.target_group_arns["bff"]

  environment_variables = {
    NODE_ENV   = "production"
    PORT       = "3000"
    LOG_LEVEL  = "warn"
    AWS_REGION = var.aws_region

    AUTH_SERVICE_URL         = "http://placeholder-auth:3001"
    DOCUMENT_SERVICE_URL     = "http://placeholder-document:3002"
    PROCESSING_SERVICE_URL   = "http://placeholder-processing:3003"
    SEARCH_SERVICE_URL       = "http://placeholder-search:3004"
    NOTIFICATION_SERVICE_URL = "http://placeholder-notification:3005"
  }

  log_retention_days = local.log_retention_days
}

# ── ECS service — WebUI (Next.js SSR) ────────────────────────────────────

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
  desired_count    = local.asg_desired
  target_group_arn = module.alb.target_group_arns["web"]

  environment_variables = {
    NODE_ENV    = "production"
    PORT        = "4000"
    LOG_LEVEL   = "warn"

    NEXT_PUBLIC_BFF_URL = length(var.domain_names) > 0 ? (
      "https://${var.domain_names[0]}"
      ) : (
      "https://${module.cloudfront.domain_name}"
    )

    NEXT_PUBLIC_S3_BUCKET_URL = "https://${module.s3.documents_bucket_domain}"
  }

  log_retention_days = local.log_retention_days
}

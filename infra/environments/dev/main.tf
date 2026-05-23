locals {
  name_prefix = "docuvault-dev"
  env         = "dev"
  az_count    = 2

  # Sizing — free tier: t3.micro EC2, db.t3.micro RDS
  ec2_instance_type  = "t3.micro"
  rds_instance_class = "db.t3.micro"
  task_cpu           = 256
  task_memory        = 512
  asg_min            = 1
  asg_max            = 2
  asg_desired        = 1
  log_retention_days = 7

  # ECR image URIs — account_id is resolved at plan time
  account_id  = data.aws_caller_identity.current.account_id
  ecr_base    = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.name_prefix}"
  webui_image = "${local.ecr_base}-web:${var.webui_image_tag}"
  bff_image   = "${local.ecr_base}-bff:${var.bff_image_tag}"
}

data "aws_caller_identity" "current" {}

# ── 1. Networking ─────────────────────────────────────────────────────────

module "vpc" {
  source      = "../../modules/vpc"
  name_prefix = local.name_prefix
  vpc_cidr    = "10.0.0.0/16"
  az_count    = local.az_count
}

# ── 2. Container registry ─────────────────────────────────────────────────

module "ecr" {
  source      = "../../modules/ecr"
  name_prefix = local.name_prefix

  repositories = [
    "web", "bff", "auth-service", "document-service",
    "processing-service", "search-service", "notification-service"
  ]

  # In dev keep only 3 images to stay inside ECR free tier (500 MB/month)
  image_retention_count = 3
}

# ── 3. SNS topic (no subscription yet — avoids circular dep with SQS) ─────

module "sns" {
  source      = "../../modules/sns"
  name_prefix = local.name_prefix
}

# ── 4. SQS queues (needs SNS ARN for notification queue policy) ───────────

module "sqs" {
  source      = "../../modules/sqs"
  name_prefix = local.name_prefix

  processing_visibility_timeout = 300
  sns_processing_topic_arn      = module.sns.processing_events_topic_arn
}

# ── 5. SNS → SQS subscription (wired here, after both modules exist) ──────

resource "aws_sns_topic_subscription" "processing_to_notification" {
  topic_arn            = module.sns.processing_events_topic_arn
  protocol             = "sqs"
  endpoint             = module.sqs.notification_queue_arn
  raw_message_delivery = true
}

# ── 6. Load balancer (HTTP only in dev — no ACM cert) ────────────────────

module "alb" {
  source      = "../../modules/alb"
  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id

  # ALB needs at least 2 public subnets across different AZs
  public_subnet_ids = module.vpc.public_subnet_ids

  default_service            = "web"
  acm_certificate_arn        = null
  enable_deletion_protection = false

  services = [
    {
      name              = "bff"
      port              = 3000
      health_check_path = "/health"
      path_patterns     = ["/api/*"]
      priority          = 10 # evaluated before the catch-all web rule
    },
    {
      name              = "web"
      port              = 4000
      health_check_path = "/"
      path_patterns     = ["/*"] # ignored — web is the default action
      priority          = 100
    }
  ]
}

# ── 7. ECS cluster (EC2 launch type) ─────────────────────────────────────

module "ecs_cluster" {
  source      = "../../modules/ecs-cluster"
  name_prefix = local.name_prefix

  # In dev, ECS EC2 instances sit in public subnets (no NAT Gateway cost)
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

# ── 8. Cognito user pool ──────────────────────────────────────────────────

module "cognito" {
  source      = "../../modules/cognito"
  name_prefix = local.name_prefix

  # In dev, callback points to the CloudFront domain (filled after first apply)
  callback_urls = ["http://localhost:4000/auth/callback"]
  logout_urls   = ["http://localhost:4000"]
}

# ── 9. DynamoDB tables ────────────────────────────────────────────────────

module "dynamodb" {
  source      = "../../modules/dynamodb"
  name_prefix = local.name_prefix
  enable_pitr = false
}

# ── 10. S3 buckets ────────────────────────────────────────────────────────

module "s3" {
  source      = "../../modules/s3"
  name_prefix = local.name_prefix

  # Allow any origin in dev — lock down to CloudFront domain in prod
  allowed_origins   = ["*"]
  enable_versioning = false
}

# ── 11. RDS PostgreSQL (free tier: db.t3.micro, 20 GB, single-AZ) ────────

module "rds" {
  source      = "../../modules/rds"
  name_prefix = local.name_prefix

  vpc_id                      = module.vpc.vpc_id
  subnet_ids                  = module.vpc.private_subnet_ids
  ecs_tasks_security_group_id = module.alb.ecs_tasks_security_group_id

  instance_class        = local.rds_instance_class
  allocated_storage     = 20
  max_allocated_storage = 20

  db_name   = "docuvault"
  db_username = "docuvault_admin"
  db_password = var.db_password

  multi_az              = false
  deletion_protection   = false
  skip_final_snapshot   = true
  backup_retention_days = 1
  performance_insights  = false
}

# ── 12. Lambda functions (ocr-trigger, thumbnail-generator, cleanup) ──────

module "lambda" {
  source      = "../../modules/lambda"
  name_prefix = local.name_prefix

  processing_queue_url  = module.sqs.processing_queue_url
  processing_queue_arn  = module.sqs.processing_queue_arn
  documents_bucket_name = module.s3.documents_bucket_name
  documents_bucket_arn  = module.s3.documents_bucket_arn
  thumbnails_bucket_name = module.s3.thumbnails_bucket_name
  thumbnails_bucket_arn  = module.s3.thumbnails_bucket_arn

  processing_jobs_table_name = module.dynamodb.processing_jobs_table_name
  processing_jobs_table_arn  = module.dynamodb.processing_jobs_table_arn

  log_retention_days = local.log_retention_days
}

# ── 13. CloudFront (CDN in front of ALB — caches Next.js static chunks) ──

module "cloudfront" {
  source      = "../../modules/cloudfront"
  name_prefix = local.name_prefix

  alb_dns_name                   = module.alb.alb_dns_name
  domain_names                   = []
  acm_certificate_arn_us_east_1  = null
  price_class                    = "PriceClass_200"
}

# ── 14. IAM task roles for ECS services ──────────────────────────────────

# BFF — aggregates calls to backend services via HTTP; no direct AWS API access
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

# WebUI — calls BFF via HTTP; no direct AWS API access
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

# ── 15. ECS service — BFF ─────────────────────────────────────────────────

module "ecs_service_bff" {
  source = "../../modules/ecs-service"

  service_name           = "bff"
  cluster_id             = module.ecs_cluster.cluster_id
  cluster_name           = module.ecs_cluster.cluster_name
  capacity_provider_name = module.ecs_cluster.capacity_provider_name
  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn          = aws_iam_role.bff_task.arn

  container_image = local.bff_image
  container_port  = 3000
  task_cpu        = local.task_cpu
  task_memory     = local.task_memory
  desired_count   = 1

  target_group_arn = module.alb.target_group_arns["bff"]

  environment_variables = {
    NODE_ENV                  = "development"
    PORT                      = "3000"
    LOG_LEVEL                 = "debug"
    AWS_REGION                = var.aws_region

    # Backend service URLs — update when each service is deployed to ECS
    AUTH_SERVICE_URL          = "http://placeholder-auth:3001"
    DOCUMENT_SERVICE_URL      = "http://placeholder-document:3002"
    PROCESSING_SERVICE_URL    = "http://placeholder-processing:3003"
    SEARCH_SERVICE_URL        = "http://placeholder-search:3004"
    NOTIFICATION_SERVICE_URL  = "http://placeholder-notification:3005"
  }

  log_retention_days = local.log_retention_days
}

# ── 16. ECS service — WebUI (Next.js) ────────────────────────────────────

module "ecs_service_webui" {
  source = "../../modules/ecs-service"

  service_name           = "web"
  cluster_id             = module.ecs_cluster.cluster_id
  cluster_name           = module.ecs_cluster.cluster_name
  capacity_provider_name = module.ecs_cluster.capacity_provider_name
  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn          = aws_iam_role.webui_task.arn

  container_image = local.webui_image
  container_port  = 4000
  task_cpu        = local.task_cpu
  task_memory     = local.task_memory
  desired_count   = 1

  target_group_arn = module.alb.target_group_arns["web"]

  environment_variables = {
    NODE_ENV              = "development"
    PORT                  = "4000"
    NEXT_PUBLIC_BFF_URL   = "http://${module.alb.alb_dns_name}"
    NEXT_PUBLIC_S3_BUCKET_URL = "https://${module.s3.documents_bucket_domain}"
  }

  log_retention_days = local.log_retention_days
}

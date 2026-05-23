output "cloudfront_domain" {
  description = "Public URL for the app — share this during development"
  value       = module.cloudfront.domain_name
}

output "alb_dns_name" {
  description = "ALB DNS — useful for direct testing without CloudFront"
  value       = module.alb.alb_dns_name
}

output "ecr_urls" {
  description = "ECR repository URLs — use these in docker build/push commands"
  value       = module.ecr.repository_urls
}

output "rds_endpoint" {
  description = "RDS hostname — use in DATABASE_URL for backend services"
  value       = module.rds.endpoint
}

output "rds_instance_id" {
  description = "Run: aws rds stop-db-instance --db-instance-identifier <id> when done developing"
  value       = module.rds.instance_id
}

output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_client_id" {
  value = module.cognito.client_id
}

output "documents_bucket_name" {
  value = module.s3.documents_bucket_name
}

output "processing_queue_url" {
  value = module.sqs.processing_queue_url
}

output "sns_processing_topic_arn" {
  value = module.sns.processing_events_topic_arn
}

output "dynamodb_processing_table" {
  value = module.dynamodb.processing_jobs_table_name
}

output "dynamodb_notification_table" {
  value = module.dynamodb.notification_log_table_name
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

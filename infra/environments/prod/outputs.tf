output "cloudfront_domain" {
  description = "Primary public URL — set your DNS CNAME here if using a custom domain"
  value       = module.cloudfront.domain_name
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID for Route 53 alias records"
  value       = module.alb.alb_zone_id
}

output "ecr_urls" {
  value = module.ecr.repository_urls
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rds_instance_id" {
  value = module.rds.instance_id
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

output "cloudfront_distribution_id" {
  description = "Use in CI/CD to invalidate the CloudFront cache after a deploy"
  value       = module.cloudfront.distribution_id
}

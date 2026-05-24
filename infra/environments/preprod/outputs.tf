output "cloudfront_domain" {
  value = module.cloudfront.domain_name
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
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

output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

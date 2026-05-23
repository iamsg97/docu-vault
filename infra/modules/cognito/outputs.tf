output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.this.arn
}

output "client_id" {
  value = aws_cognito_user_pool_client.this.id
}

output "domain" {
  description = "Cognito hosted UI domain prefix (not full URL)"
  value       = aws_cognito_user_pool_domain.this.domain
}

output "endpoint" {
  description = "Cognito user pool endpoint — used in auth-service JWKS verification"
  value       = aws_cognito_user_pool.this.endpoint
}

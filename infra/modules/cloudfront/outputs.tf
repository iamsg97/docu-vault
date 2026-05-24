output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "domain_name" {
  description = "CloudFront assigned domain — share this with users when no custom domain is configured"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "CloudFront hosted zone ID — used in Route 53 alias records"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

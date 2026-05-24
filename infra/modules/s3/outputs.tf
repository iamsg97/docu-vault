output "documents_bucket_name" {
  value = aws_s3_bucket.documents.bucket
}

output "documents_bucket_arn" {
  value = aws_s3_bucket.documents.arn
}

output "documents_bucket_domain" {
  value = aws_s3_bucket.documents.bucket_regional_domain_name
}

output "thumbnails_bucket_name" {
  value = aws_s3_bucket.thumbnails.bucket
}

output "thumbnails_bucket_arn" {
  value = aws_s3_bucket.thumbnails.arn
}

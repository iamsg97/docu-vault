output "processing_jobs_table_name" {
  value = aws_dynamodb_table.processing_jobs.name
}

output "notification_log_table_name" {
  value = aws_dynamodb_table.notification_log.name
}

output "user_sessions_table_name" {
  value = aws_dynamodb_table.user_sessions.name
}

output "processing_jobs_table_arn" {
  value = aws_dynamodb_table.processing_jobs.arn
}

output "notification_log_table_arn" {
  value = aws_dynamodb_table.notification_log.arn
}

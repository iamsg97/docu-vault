output "processing_queue_url" {
  value = aws_sqs_queue.processing.url
}

output "processing_queue_arn" {
  value = aws_sqs_queue.processing.arn
}

output "notification_queue_url" {
  value = aws_sqs_queue.notification.url
}

output "notification_queue_arn" {
  value = aws_sqs_queue.notification.arn
}

output "processing_dlq_url" {
  value = aws_sqs_queue.processing_dlq.url
}

output "notification_dlq_url" {
  value = aws_sqs_queue.notification_dlq.url
}

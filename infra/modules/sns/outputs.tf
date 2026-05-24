output "processing_events_topic_arn" {
  value = aws_sns_topic.processing_events.arn
}

output "processing_events_topic_name" {
  value = aws_sns_topic.processing_events.name
}

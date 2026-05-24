# ── Processing queue — S3 upload events → processing-service ─────────────

resource "aws_sqs_queue" "processing_dlq" {
  name                      = "${var.name_prefix}-processing-queue-dlq"
  message_retention_seconds = 1209600 # 14 days — retain failed messages for investigation

  tags = { Name = "${var.name_prefix}-processing-queue-dlq" }
}

resource "aws_sqs_queue" "processing" {
  name                       = "${var.name_prefix}-processing-queue"
  visibility_timeout_seconds = var.processing_visibility_timeout
  message_retention_seconds  = 86400 # 1 day

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.processing_dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Name = "${var.name_prefix}-processing-queue" }
}

resource "aws_sqs_queue_redrive_allow_policy" "processing_dlq" {
  queue_url = aws_sqs_queue.processing_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.processing.arn]
  })
}

# ── Notification queue — SNS fan-out → notification-service ───────────────

resource "aws_sqs_queue" "notification_dlq" {
  name                      = "${var.name_prefix}-notification-queue-dlq"
  message_retention_seconds = 1209600

  tags = { Name = "${var.name_prefix}-notification-queue-dlq" }
}

resource "aws_sqs_queue" "notification" {
  name                       = "${var.name_prefix}-notification-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Name = "${var.name_prefix}-notification-queue" }
}

resource "aws_sqs_queue_redrive_allow_policy" "notification_dlq" {
  queue_url = aws_sqs_queue.notification_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.notification.arn]
  })
}

# Queue policy — allow SNS to publish to notification-queue
resource "aws_sqs_queue_policy" "notification" {
  queue_url = aws_sqs_queue.notification.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.notification.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = var.sns_processing_topic_arn
        }
      }
    }]
  })
}

# CloudWatch alarms on DLQs — fire when a message lands in the dead-letter queue
resource "aws_cloudwatch_metric_alarm" "processing_dlq" {
  alarm_name          = "${var.name_prefix}-processing-dlq-not-empty"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Messages arrived in the processing DLQ — investigate processing-service"

  dimensions = {
    QueueName = aws_sqs_queue.processing_dlq.name
  }

  tags = { Name = "${var.name_prefix}-processing-dlq-alarm" }
}

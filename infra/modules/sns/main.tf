# Processing events topic — processing-service publishes here after OCR completes.
# The subscription (SNS → SQS) lives in each environment's main.tf to avoid
# a circular module dependency (SQS needs this ARN for its queue policy).

resource "aws_sns_topic" "processing_events" {
  name = "${var.name_prefix}-processing-events"
  tags = { Name = "${var.name_prefix}-processing-events" }
}

variable "name_prefix" {
  type = string
}

variable "processing_visibility_timeout" {
  description = "Seconds a message is hidden after a consumer picks it up — must exceed max processing time"
  type        = number
  default     = 300
}

variable "sns_processing_topic_arn" {
  description = "SNS topic ARN allowed to publish to the notification queue"
  type        = string
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "db_password" {
  description = "RDS master password — set via TF_VAR_db_password env var, never hardcode"
  type        = string
  sensitive   = true
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (ap-south-1) for ALB HTTPS listener"
  type        = string
  default     = null
}

variable "acm_certificate_arn_us_east_1" {
  description = "ACM certificate ARN (us-east-1) for CloudFront viewer cert"
  type        = string
  default     = null
}

variable "domain_names" {
  description = "Custom domain aliases for CloudFront (e.g. ['app.docuvault.io'])"
  type        = list(string)
  default     = []
}

variable "webui_image_tag" {
  type    = string
  default = "latest"
}

variable "bff_image_tag" {
  type    = string
  default = "latest"
}

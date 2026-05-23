variable "name_prefix" {
  type = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB — CloudFront uses this as its origin"
  type        = string
}

variable "domain_names" {
  description = "Custom domain aliases (e.g. ['app.docuvault.io']). Empty list = use CloudFront default domain."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn_us_east_1" {
  description = "ACM certificate ARN in us-east-1 (CloudFront requires us-east-1). Omit to use the free CloudFront default cert."
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class — PriceClass_200 covers Asia Pacific (ap-south-1 users)"
  type        = string
  default     = "PriceClass_200"
}

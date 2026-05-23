variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  description = "Public subnets — ALB must span at least two AZs"
  type        = list(string)
}

variable "services" {
  description = "Services to route to. Each entry creates a target group and (optionally) a listener rule."
  type = list(object({
    name              = string
    port              = number
    health_check_path = string
    path_patterns     = list(string) # e.g. ["/api/*"] — ignored for the default service
    priority          = number       # lower = evaluated first; ignored for the default service
  }))
}

variable "default_service" {
  description = "Name of the service that receives the default (catch-all) action — usually the frontend"
  type        = string
  default     = "web"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS. Omit in dev to run HTTP-only."
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Prevent accidental ALB deletion — enable in prod"
  type        = bool
  default     = false
}

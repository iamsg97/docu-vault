variable "service_name" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "capacity_provider_name" {
  type = string
}

variable "task_execution_role_arn" {
  description = "Shared execution role — ECR pull + CloudWatch Logs write"
  type        = string
}

variable "task_role_arn" {
  description = "Per-service task role — grants the running container access to AWS APIs"
  type        = string
  default     = null
}

variable "container_image" {
  description = "Full ECR image URI including tag (e.g. 123456.dkr.ecr.ap-south-1.amazonaws.com/docuvault-web:latest)"
  type        = string
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "task_cpu" {
  description = "CPU units reserved for the task (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory in MB reserved for the task"
  type        = number
  default     = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "environment_variables" {
  description = "Plain-text env vars injected into the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret env vars — map of ENV_NAME → SSM Parameter Store ARN or Secrets Manager ARN"
  type        = map(string)
  default     = {}
}

variable "target_group_arn" {
  description = "ALB target group ARN — omit for services not behind the ALB"
  type        = string
  default     = null
}

variable "health_check_command" {
  description = "Shell command the container runs to report healthy (e.g. 'curl -f http://localhost:3000/health || exit 1')"
  type        = string
  default     = null
}

variable "log_retention_days" {
  type    = number
  default = 7
}

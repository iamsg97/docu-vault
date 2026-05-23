variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnets for the RDS instance"
  type        = list(string)
}

variable "ecs_tasks_security_group_id" {
  description = "SG of ECS tasks — granted inbound access to port 5432"
  type        = string
}

variable "instance_class" {
  description = "db.t3.micro is free-tier eligible"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GB (free tier: 20 GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  type    = string
  default = "docuvault"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  description = "Pass via TF_VAR_db_password env var — never hardcode"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ standby — costs double; enable only in prod"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevent accidental deletion — enable in prod"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy — set true in dev"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Days to retain automated backups (0 disables; free tier: 7 days)"
  type        = number
  default     = 7
}

variable "performance_insights" {
  description = "Enable RDS Performance Insights — free for 7-day retention"
  type        = bool
  default     = false
}

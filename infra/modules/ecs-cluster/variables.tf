variable "name_prefix" {
  type = string
}

variable "subnet_ids" {
  description = "Subnets to launch EC2 instances into (public in dev, private in prod)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups to attach to ECS EC2 instances"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type — t3.micro is free-tier eligible"
  type        = string
  default     = "t3.micro"
}

variable "asg_min" {
  type    = number
  default = 1
}

variable "asg_max" {
  type    = number
  default = 3
}

variable "asg_desired" {
  type    = number
  default = 1
}

variable "associate_public_ip" {
  description = "Give EC2 instances public IPs — required in public subnets without NAT"
  type        = bool
  default     = true
}

variable "container_insights" {
  description = "Enable CloudWatch Container Insights (costs extra — disable in dev)"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  type    = number
  default = 7
}

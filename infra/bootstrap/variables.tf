variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
  default     = "docuvault"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "aws_account_id" {
  description = "AWS account ID — appended to state bucket name to ensure global uniqueness"
  type        = string
}

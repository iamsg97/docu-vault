variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "db_password" {
  description = "RDS master password — set via TF_VAR_db_password env var, never hardcode"
  type        = string
  sensitive   = true
}

variable "webui_image_tag" {
  type    = string
  default = "latest"
}

variable "bff_image_tag" {
  type    = string
  default = "latest"
}

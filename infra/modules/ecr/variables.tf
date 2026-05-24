variable "name_prefix" {
  type = string
}

variable "repositories" {
  description = "List of service names; each becomes a repo named <prefix>-<service>"
  type        = list(string)
}

variable "image_retention_count" {
  description = "Maximum tagged images to retain per repository"
  type        = number
  default     = 5
}

variable "name_prefix" {
  type = string
}

variable "enable_pitr" {
  description = "Enable Point-in-Time Recovery — free for DynamoDB; disable in dev to be explicit"
  type        = bool
  default     = false
}

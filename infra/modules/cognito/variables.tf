variable "name_prefix" {
  type = string
}

variable "callback_urls" {
  description = "Allowed redirect URLs after successful login (frontend URL)"
  type        = list(string)
  default     = ["http://localhost:4000/auth/callback"]
}

variable "logout_urls" {
  description = "Allowed redirect URLs after logout"
  type        = list(string)
  default     = ["http://localhost:4000"]
}

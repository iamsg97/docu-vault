variable "name_prefix" {
  type = string
}

variable "allowed_origins" {
  description = "Origins permitted to make CORS requests to the documents bucket (frontend URL)"
  type        = list(string)
  default     = ["*"]
}

variable "enable_versioning" {
  description = "Enable S3 object versioning on the documents bucket"
  type        = bool
  default     = false
}

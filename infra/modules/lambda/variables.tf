variable "name_prefix" {
  type = string
}

variable "processing_queue_url" {
  type = string
}

variable "processing_queue_arn" {
  type = string
}

variable "documents_bucket_name" {
  type = string
}

variable "documents_bucket_arn" {
  type = string
}

variable "thumbnails_bucket_name" {
  type = string
}

variable "thumbnails_bucket_arn" {
  type = string
}

variable "processing_jobs_table_name" {
  type = string
}

variable "processing_jobs_table_arn" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 7
}

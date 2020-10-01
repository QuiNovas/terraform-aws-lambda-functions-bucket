variable "cross_account_users" {
  default     = []
  description = "A list of users (normally root users) that can access the lambda bucket across accounts."
  type        = list(string)
}

variable "log_bucket_id" {
  description = "The bucket to log S3 logs to."
  type        = string
}


variable "logging" {
  description = "object containing access bucket logging configuration."
  type        = map(string)
  default     = {}
}


variable "name_prefix" {
  description = "The name prefix to use when creating resource names"
  type        = string
}


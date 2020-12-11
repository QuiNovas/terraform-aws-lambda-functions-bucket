variable "cross_account_users" {
  default     = []
  description = "A list of users (normally root users) that can access the lambda bucket across accounts."
  type        = list(string)
}

variable "log_bucket_id" {
  description = "The bucket to log S3 logs to. Required if Logging is enabled"
  type        = string
  default     = ""
}

variable "block_all_public_access" {
  description = "Enable this too ensure that public access to all your S3 bucket and objects is blocked"
  type        = string
  default     = true
}

variable "logging" {
  description = "whether server access logging should be enabled or disabled.by default it is enabled."
  type        = bool
  default     = true
}

variable "name_prefix" {
  description = "The name prefix to use when creating resource names"
  type        = string
}

variable "name_suffix" {
  description = "The name suffix for resource names"
  type        = string
  default     = "-lambda-functions"
}

variable "replication_enabled" {
  description = "Enable or Disable replication to destination buckets. Basic root level replication. This module supports only non kms objects"
  type        = bool
  default     = false
}

variable "destination_buckets" {
  description = "List of buckets for replication"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
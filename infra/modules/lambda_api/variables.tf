variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "lambda_security_group_id" {
  type = string
}

variable "artifact_bucket_name" {
  type = string
}

variable "artifact_s3_key" {
  description = "S3 key of the Lambda deployment zip inside the artifact bucket. Updated each CI run."
  type        = string
  default     = "lambda/app.zip"
}

variable "artifact_s3_object_version" {
  description = "S3 object version of the deployment zip. Changing this is what makes Terraform deploy new app code."
  type        = string
}

variable "db_secret_arn" {
  type = string
}

variable "db_secret_kms_key_arn" {
  type = string
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "handler" {
  type    = string
  default = "handler.handler"
}

variable "memory_size" {
  type    = number
  default = 256
}

variable "timeout" {
  type    = number
  default = 10
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "rate_limit_per_5min" {
  description = "WAF rate-based rule: max requests per 5-minute window per source IP."
  type        = number
  default     = 2000
}

variable "tags" {
  type    = map(string)
  default = {}
}

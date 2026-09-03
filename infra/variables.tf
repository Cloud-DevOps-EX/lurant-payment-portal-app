variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "payment-portal"
}

variable "environment" {
  description = "Single environment for now (e.g. \"prod\"). Structured to add dev/staging later via a separate state key + var-file."
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_deletion_protection" {
  type    = bool
  default = true
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = false
}

variable "artifact_s3_key" {
  description = "S3 key of the Lambda deployment zip, uploaded by CI before terraform apply."
  type        = string
  default     = "lambda/app.zip"
}

variable "artifact_s3_object_version" {
  description = "S3 object version of the deployment zip just uploaded by CI. Required — there is no default because it must reflect the artifact actually being deployed."
  type        = string
}

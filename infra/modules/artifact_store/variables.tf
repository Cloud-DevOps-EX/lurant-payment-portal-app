variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "account_id" {
  description = "Used to keep the bucket name globally unique."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

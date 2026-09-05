variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "db_security_group_id" {
  type = string
}

variable "engine_version" {
  description = "PostgreSQL major/minor engine version."
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20

}

variable "max_allocated_storage" {
  description = "Ceiling for RDS storage autoscaling."
  type        = number
  default     = 100
}

variable "database_name" {
  type    = string
  default = "payment_portal"
}

variable "master_username" {
  type    = string
  default = "app_admin"
}

variable "backup_retention_days" {
  type    = number
  default = 6
}

variable "deletion_protection" {
  description = "Set false only for throwaway/dev stacks you intend to destroy."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Set false in production so a snapshot is taken on destroy."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

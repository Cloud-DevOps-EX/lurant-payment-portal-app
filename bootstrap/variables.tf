variable "aws_region" {
  description = "AWS region for the Terraform state backend and OIDC role."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier used to name/tag bootstrap resources."
  type        = string
  default     = "payment-portal"
}

variable "github_org" {
  description = "GitHub organization or user that owns the repository (case-sensitive)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without the org prefix)."
  type        = string
}

variable "create_oidc_provider" {
  description = "Whether to create the GitHub Actions OIDC provider. Set to false if one already exists for token.actions.githubusercontent.com in this AWS account (only one is allowed per account)."
  type        = bool
  default     = false
}

variable "existing_oidc_provider_arn" {
  description = "ARN of an existing GitHub OIDC provider to reuse when create_oidc_provider = false."
  type        = string
  default     = ""
}

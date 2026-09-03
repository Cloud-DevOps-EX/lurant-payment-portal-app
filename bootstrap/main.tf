## One-time bootstrap: Terraform remote state backend + GitHub Actions OIDC role.
## Apply this manually (terraform init && terraform apply) BEFORE any CI/CD pipeline
## run, and BEFORE infra/backend.tf is filled in — this is the chicken/egg piece
## that CI cannot provision for itself. See ../README.md for the full sequence.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  state_bucket_name = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
  lock_table_name   = "${var.project_name}-tfstate-lock"

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
    Component = "bootstrap"
  }
}

# ---------------------------------------------------------------------------
# Terraform remote state: S3 bucket (versioned, encrypted, private) + DynamoDB
# lock table.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "tf_state" {
  bucket = local.state_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "tf_state_tls_only" {
  bucket = aws_s3_bucket.tf_state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.tf_state.arn,
        "${aws_s3_bucket.tf_state.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.tags
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC federation: lets workflow runs in github_org/github_repo
# assume an AWS role with no long-lived access keys stored in GitHub.
# ---------------------------------------------------------------------------

data "tls_certificate" "github" {
  count = var.create_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github[0].certificates[0].sha1_fingerprint]
  tags            = local.tags
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
}

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Allow jobs from this exact repo. Include both the name-based subject
    # (repo:org/repo:...) and the immutable ID form GitHub may emit
    # (repo:org@id/repo@id:...). Environment-gated jobs use
    # "...:environment:<name>" rather than "...:ref:refs/heads/...".
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:*",
        "repo:${var.github_org}@*/${var.github_repo}@*:*",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
  tags               = local.tags
}

# Scoped (not admin) permissions for everything the pipeline provisions:
# networking, RDS, Lambda, API Gateway, WAF, Secrets Manager, KMS, the two S3
# buckets (state + artifacts), the DynamoDB lock table, and IAM PassRole for
# the Lambda execution role Terraform creates in infra/modules/lambda_api.
data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid    = "TerraformState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.tf_state.arn,
      "${aws_s3_bucket.tf_state.arn}/*",
    ]
  }

  statement {
    sid       = "TerraformLock"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.tf_lock.arn]
  }

  statement {
    sid    = "ArtifactBucket"
    effect = "Allow"
    # Full s3:* on the artifact bucket only — Terraform needs many non-
    # GetBucket* APIs (GetAccelerateConfiguration, PutLifecycleConfiguration,
    # GetEncryptionConfiguration, etc.) when managing the bucket.
    actions   = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.project_name}-lambda-artifacts-*",
      "arn:aws:s3:::${var.project_name}-lambda-artifacts-*/*",
    ]
  }

  statement {
    sid    = "InfraProvisioning"
    effect = "Allow"
    actions = [
      "ec2:*",
      "rds:*",
      "lambda:*",
      "apigateway:*",
      "wafv2:*",
      "logs:*",
      "kms:*",
      "secretsmanager:*",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:TagRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:CreateServiceLinkedRole",
    ]
    resources = ["*"]
    # NOTE: ec2/rds/lambda/apigateway/wafv2/kms/secretsmanager do not support
    # useful resource-level scoping for the actions Terraform needs (create/
    # describe/tag across many resource types), so this is deliberately AWS
    # managed-service-broad rather than account-admin-broad. Tighten with
    # permission boundaries or SCPs at the org level if required.
  }

  statement {
    sid       = "PassLambdaExecutionRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "${var.project_name}-github-actions-permissions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}

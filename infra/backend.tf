## Partial backend configuration on purpose: the bucket/table/region are
## account-specific outputs from ../bootstrap, so they're supplied at init
## time via -backend-config instead of being hardcoded here.
##
## Local use:
##   terraform init \
##     -backend-config="bucket=<state_bucket_name from bootstrap output>" \
##     -backend-config="key=payment-portal/terraform.tfstate" \
##     -backend-config="region=<aws_region>" \
##     -backend-config="dynamodb_table=<lock_table_name from bootstrap output>"
##
## CI does the same thing using repo variables — see
## .github/workflows/terraform.yml.
terraform {
  backend "s3" {
    encrypt = true
  }
}

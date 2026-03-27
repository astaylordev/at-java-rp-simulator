# Root Terragrunt configuration for the scratch environment.
# Found automatically by find_in_parent_folders() in child modules.
#
# Pre-requisites before running terragrunt:
#   1. Run env/scratch/bootstrap.sh to create the S3 state bucket,
#      DynamoDB lock table, and SSM parameters.
#   2. Ensure AWS credentials are configured (e.g. via AWS_PROFILE or SSO).
#   3. Set OIDC_ISSUER_URI environment variable.
#   4. Build and push the Docker image to ECR, then set CONTAINER_IMAGE_TAG.

locals {
  aws_region = "ca-central-1"
  env        = "scratch"
  service    = "rp-simulator"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    encrypt        = true
    bucket         = "${local.service}-${local.env}-tf"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = "${local.service}-${local.env}-tf-lock"

    s3_bucket_tags = {
      CostCentre = local.service
    }
    dynamodb_table_tags = {
      CostCentre = local.service
    }
  }
}

inputs = {
  billing_tag_key   = "CostCentre"
  billing_tag_value = local.service
}

locals {
  # Override via: CONTAINER_IMAGE_TAG=abc123 terragrunt apply
  ecr_image_tag = get_env("CONTAINER_IMAGE_TAG", "latest")
  ssm_prefix    = "/java-rp-simulator/scratch"
}

terraform {
  source = "../../../aws//ecs"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan"]
  mock_outputs_merge_with_state           = true
  mock_outputs = {
    repository_url = "000000000000.dkr.ecr.ca-central-1.amazonaws.com/rp-simulator"
  }
}

dependency "networking" {
  config_path = "../networking"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan"]
  mock_outputs_merge_with_state           = true
  mock_outputs = {
    private_subnet_ids    = ["subnet-00000000000000001", "subnet-00000000000000002"]
    ecs_security_group_id = "sg-00000000000000001"
    alb_target_group_arn  = "arn:aws:elasticloadbalancing:ca-central-1:000000000000:targetgroup/rp-simulator/0000000000000000"
  }
}

inputs = {
  service_name    = "rp-simulator"
  container_image = "${dependency.ecr.outputs.repository_url}:${local.ecr_image_tag}"

  private_subnet_ids    = dependency.networking.outputs.private_subnet_ids
  ecs_security_group_id = dependency.networking.outputs.ecs_security_group_id
  lb_target_group_arn   = dependency.networking.outputs.alb_target_group_arn

  # Set OIDC_ISSUER_URI in your shell before running terragrunt
  # e.g. export OIDC_ISSUER_URI=https://login.microsoftonline.com/<tenant>/v2.0
  oidc_issuer_uri = get_env("OIDC_ISSUER_URI")
  oidc_scopes     = "openid,profile,email"

  # OIDC client ID and secret are stored in SSM and fetched by ECS at runtime.
  # Create them with bootstrap.sh or manually via the AWS console/CLI.
  oidc_client_id_ssm_path     = "${local.ssm_prefix}/oidc-client-id"
  oidc_client_secret_ssm_path = "${local.ssm_prefix}/oidc-client-secret"
}

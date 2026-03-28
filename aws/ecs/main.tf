data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  oidc_client_id_ssm_arn     = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.oidc_client_id_ssm_path}"
  oidc_client_secret_ssm_arn = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.oidc_client_secret_ssm_path}"
}

# IAM policy allowing the ECS task execution role to fetch secrets from SSM
data "aws_iam_policy_document" "task_exec_ssm" {
  statement {
    sid    = "AllowSSMParameterAccess"
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
    ]
    resources = [
      local.oidc_client_id_ssm_arn,
      local.oidc_client_secret_ssm_arn,
    ]
  }
}

module "ecs" {
  source = "github.com/cds-snc/terraform-modules//ecs?ref=main"

  cluster_name = var.service_name
  service_name = var.service_name

  task_cpu    = var.task_cpu
  task_memory = var.task_memory

  # Container image is set by CI/CD via CONTAINER_IMAGE_TAG env var passed to terragrunt
  container_image     = var.container_image
  container_port      = 8080
  container_host_port = 8080

  # Non-secret config passed as environment variables
  container_environment = [
    { name = "OIDC_ISSUER_URI", value = var.oidc_issuer_uri },
    { name = "OIDC_SCOPES", value = var.oidc_scopes },
    { name = "APP_BASE_URL", value = var.app_base_url },
  ]

  # Secrets fetched from SSM Parameter Store at task startup
  container_secrets = [
    { name = "OIDC_CLIENT_ID", valueFrom = var.oidc_client_id_ssm_path },
    { name = "OIDC_CLIENT_SECRET", valueFrom = var.oidc_client_secret_ssm_path },
  ]

  container_health_check = {
    command     = ["CMD-SHELL", "wget -q -O /dev/null http://localhost:8080/actuator/health || exit 1"]
    interval    = 30
    timeout     = 5
    retries     = 3
    startPeriod = 60
  }

  # Spring Boot (Tomcat) writes temp files — disable read-only root filesystem
  container_read_only_root_filesystem = false

  lb_target_group_arn = var.lb_target_group_arn
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.ecs_security_group_id]

  # Grant the task execution role access to the SSM parameters
  task_exec_role_policy_documents = [data.aws_iam_policy_document.task_exec_ssm.json]

  billing_tag_value = var.billing_tag_value
}

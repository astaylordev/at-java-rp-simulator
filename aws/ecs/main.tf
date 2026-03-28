data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "oidc_client_id" {
  name = var.oidc_client_id_secret_name
}

data "aws_secretsmanager_secret" "oidc_client_secret" {
  name = var.oidc_client_secret_secret_name
}

# IAM policy allowing the ECS task execution role to fetch secrets from Secrets Manager
data "aws_iam_policy_document" "task_exec_secrets" {
  statement {
    sid    = "AllowSecretsManagerAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      data.aws_secretsmanager_secret.oidc_client_id.arn,
      data.aws_secretsmanager_secret.oidc_client_secret.arn,
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

  # Secrets fetched from Secrets Manager at task startup
  container_secrets = [
    { name = "OIDC_CLIENT_ID", valueFrom = data.aws_secretsmanager_secret.oidc_client_id.arn },
    { name = "OIDC_CLIENT_SECRET", valueFrom = data.aws_secretsmanager_secret.oidc_client_secret.arn },
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

  # Grant the task execution role access to the Secrets Manager secrets
  task_exec_role_policy_documents = [data.aws_iam_policy_document.task_exec_secrets.json]

  billing_tag_value = var.billing_tag_value
}

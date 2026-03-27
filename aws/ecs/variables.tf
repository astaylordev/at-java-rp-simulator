variable "service_name" {
  description = "Name of the ECS cluster and service"
  type        = string
}

variable "container_image" {
  description = "Container image URL including tag (e.g. 123456789.dkr.ecr.ca-central-1.amazonaws.com/rp-simulator:abc123)"
  type        = string
}

variable "task_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB (must be valid for the chosen task_cpu)"
  type        = number
  default     = 1024
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID attached to ECS tasks"
  type        = string
}

variable "lb_target_group_arn" {
  description = "ALB target group ARN to register ECS tasks against"
  type        = string
}

variable "oidc_issuer_uri" {
  description = "OIDC provider issuer URI (e.g. https://login.microsoftonline.com/<tenant>/v2.0)"
  type        = string
}

variable "oidc_scopes" {
  description = "Space or comma-separated OIDC scopes"
  type        = string
  default     = "openid,profile,email"
}

variable "oidc_client_id_ssm_path" {
  description = "SSM parameter path for the OIDC client ID (e.g. /rp-simulator/scratch/oidc-client-id)"
  type        = string
}

variable "oidc_client_secret_ssm_path" {
  description = "SSM parameter path for the OIDC client secret (e.g. /rp-simulator/scratch/oidc-client-secret)"
  type        = string
}

variable "billing_tag_key" {
  description = "The name of the billing tag"
  type        = string
  default     = "CostCentre"
}

variable "billing_tag_value" {
  description = "The value of the billing tag"
  type        = string
}

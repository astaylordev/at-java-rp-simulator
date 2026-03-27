output "cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "task_definition_arn" {
  description = "Full ARN of the active task definition"
  value       = module.ecs.task_definition_arn
}

output "task_exec_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.ecs.task_exec_role_arn
}

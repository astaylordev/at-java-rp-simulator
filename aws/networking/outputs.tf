output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (used for ECS tasks)"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs (used for ALB)"
  value       = module.vpc.public_subnet_ids
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ECS tasks security group ID"
  value       = aws_security_group.ecs.id
}

output "alb_target_group_arn" {
  description = "ALB target group ARN"
  value       = aws_lb_target_group.app.arn
}

output "alb_dns_name" {
  description = "ALB public DNS name — use this as the base URL for your OIDC redirect URI"
  value       = aws_lb.app.dns_name
}

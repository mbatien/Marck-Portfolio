output "app_url" {
  description = "open in a browser"
  value = "http://${module.alb.dns_name}"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs_service.cluster_name
}

output "ecs_service_name" {
  value = module.ecs_service.service_name
}

output "db_endpoint" {
  value = module.rds.endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager ARN of the database credentials."
  value       = module.rds.master_user_secret_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
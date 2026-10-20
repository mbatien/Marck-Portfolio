output "app_url" {
  description = "Open this in a browser."
  value       = "http://${module.alb.dns_name}"
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
  value = module.rds.master_user_secret_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

locals {
    name = "${var.app_name}-${var.environment}" 
}

module "vpc" {
    source = "../../modules/vpc"

    name                     = local.name
    cidr_block               = var.vpc_cidr 
    azs                      = var.azs
    single_nat_gateway       = var.single_nat_gateway
    flow_logs_retention_days = var.log_retention_days
}

module "ecr" {
    source = "../../modules/ecr"

    name         = "${var.app_name}-api-${var.environment}"
    force_delete = var.environment != "prod"
}

module "alb" {
    source = "../../modules/alb"

    name                = local.name
    vpc_id              = module.vpc.vpc_id
    vpc_cidr            = module.vpc.vpc_cidr
    public_subnet_ids   = module.vpc.public_subnet_ids
    target_port         = var.container_port
    health_check_path   = var.health_check_path
    certificate_arn     = var.certificate_arn
    deletion_protection = var.environment == "prod"
}

module "rds" {
    source = "../../modules/rds-postgres"

    name                       = local.name
    vpc_id                     = module.vpc.vpc_id
    data_subnet_ids            = module.vpc.data_subnet_ids
    allowed_security_group_ids = [module.ecs_service.security_group_id]
    instance_class             = var.db_instance_class
    multi_az                   = var.db_multi_az
    deletion_protection        = var.environment == "prod"
    skip_final_snapshot        = var.environment != "prod"
    backup_retention_days      = var.environment == "prod" ? 14 : 1
    apply_immediately          = var.environment != "prod"
}

module "ecs_service" {
    source = "../../modules/ecs-service"
    
    name                 = local.name
    vpc_id               = module.vpc.vpc_id
    app_subnet_ids       = module.vpc.app_subnet_ids
    alb_security_group_id = module.alb.security_group_id
    target_group_arn     = module.alb.target_group_arn
    container_image      = var.container_image
    container_port       = var.container_port
    task_cpu            = var.task_cpu
    task_memory         = var.task_memory
    desired_count        = var.desired_count
    min_count            = var.min_count
    max_count            = var.max_count
    log_retention_days   = var.log_retention_days

    environment_variables = {
       APP_ENV = var.environment
       DB_HOST = module.rds.address
       DB_PORT = tostring(module.rds.port)
        DB_NAME = module.rds.db_name
    }

    secrets = {
        DB_USERNAME = "${module.rds.master_user_secret_arn}:username::"
        DB_PASSWORD = "${module.rds.master_user_secret_arn}:password::"
    }
    secret_arns = [module.rds.master_user_secret_arn]
}




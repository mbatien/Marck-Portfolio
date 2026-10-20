environment = "prod"
region      = "us-east-1"
owner       = "your-github-username"

vpc_cidr           = "10.20.0.0/16"
azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
single_nat_gateway = false # one NAT per AZ

container_image   = "public.ecr.aws/nginx/nginx:stable"
container_port    = 8080
health_check_path = "/health"

task_cpu      = 512
task_memory   = 1024
desired_count = 3
min_count     = 3
max_count     = 6

db_instance_class = "db.t4g.small"
db_multi_az       = true

log_retention_days = 30

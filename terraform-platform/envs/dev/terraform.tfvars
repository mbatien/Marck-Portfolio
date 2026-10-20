environment = "dev"
region      = "us-east-1"
owner       = "mbastien"

vpc_cidr           = "10.0.0.0/16"
azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
single_nat_gateway = true 

container_image   = "public.ecr.aws/nginx/nginx:stable"
container_port    = 80
health_check_path = "/"

task_cpu      = 256
task_memory   = 512
desired_count = 1
min_count     = 1
max_count     = 2
db_instance_class = "db.t4g.micro"
db_multi_az       = false   

log_retention_days = 7
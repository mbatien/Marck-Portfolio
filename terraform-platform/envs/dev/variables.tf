variable "environment" {
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be \"dev\" or \"prod\"."
  }
}

variable "region" {
    type   = string
    default = "us-east-1"
}

variable "owner" {
  type        = string
}

variable "app_name" {
  type    = string
  default = "orders"
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "single_nat_gateway" {
  type = bool
}

variable "container_image" {
  type        = string
}

variable "container_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "certificate_arn" {
  type        = string
  default     = null
}

variable "task_cpu" {
  type = number
}

variable "task_memory" {
  type = number
}

variable "desired_count" {
  type = number
}

variable "min_count" {
  type = number
}

variable "max_count" {
  type = number
}

variable "db_instance_class" {
  type = string
}

variable "db_multi_az" {
  type = bool
}

variable "log_retention_days" {
  type    = number
}

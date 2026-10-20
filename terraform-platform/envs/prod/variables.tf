variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be \"dev\" or \"prod\"."
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "owner" {
  description = "Tag identifying who owns these resources"
  type        = string
}

variable "app_name" {
  type    = string
  default = "orders"
}

# ---------- network ----------

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "single_nat_gateway" {
  type = bool
}

# ---------- application ----------

variable "container_image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "certificate_arn" {
  description = "ACM certificate for HTTPS on the ALB (optional)."
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

# ---------- database ----------

variable "db_instance_class" {
  type = string
}

variable "db_multi_az" {
  type = bool
}

# ---------- logging ----------
variable "log_retention_days" {
  type = number
}

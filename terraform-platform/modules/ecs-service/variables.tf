variable "name" {
  description = "Name for the cluster, service and related resources."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "app_subnet_ids" {
  description = "Private subnets for the tasks."
  type        = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "container_image" {
  description = "Full image reference. Starts as a public placeholder; Project 2 deploys your own image."
  type        = string
}

variable "container_port" {
  type = number
}

variable "task_cpu" {
  description = "CPU units (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory in MiB."
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "X86_64 or ARM64 (Graviton, cheaper - your image must support it)."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "min_count" {
  type    = number
  default = 1
}

variable "max_count" {
  type    = number
  default = 3
}

variable "health_check_grace_period" {
  description = "Seconds to ignore failing health checks after a task starts."
  type        = number
  default     = 60
}

variable "environment_variables" {
  description = "non-secret environment variables."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret environment variables."
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = "Secret ARNs the execution role may read."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  type    = number
  default = 30
}

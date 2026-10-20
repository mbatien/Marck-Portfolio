variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "data_subnet_ids" {
  description = "Private data-tier subnets (at least 2 AZs)."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect on 5432 (e.g. the ECS service)."
  type        = list(string)
  default     = []
}

variable "engine_version" {
  description = "Major version is enough; RDS picks the latest minor."
  type        = string
  default     = "16"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_name" {
  type    = string
  default = "orders"
}

variable "master_username" {
  type    = string
  default = "app_admin"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "multi_az" {
  description = "Standby in a second AZ with automatic failover (prod)."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  type    = number
  default = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention must be 1-35 days (automated backups enable point-in-time recovery)."
  }
}

variable "deletion_protection" {
  description = "AWS refuses to delete the database while true (prod)."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "true only for disposable environments (dev)."
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Not supported on every small instance class; enable on larger classes."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply modifications now instead of in the next maintenance window."
  type        = bool
  default     = false
}

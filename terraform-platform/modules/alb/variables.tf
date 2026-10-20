variable "name" {
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  description = "Used to limit the ALB's outbound traffic to the VPC."
  type        = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "target_port" {
  description = "Port the app containers listen on."
  type        = number
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "certificate_arn" {
  type        = string
  default     = null
}

variable "deletion_protection" {
  type    = bool
  default = false
}
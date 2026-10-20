variable "name" {
  description = "Name prefix for every resource, e.g. orders-dev."
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR. Must be a /16 so the subnet math in main.tf fits."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0)) && endswith(var.cidr_block, "/16")
    error_message = "cidr_block must be a valid /16, e.g. 10.20.0.0/16."
  }
}

variable "azs" {
  description = "Availability Zones to use (3 recommended)."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2 && length(var.azs) <= 3
    error_message = "Use 2 or 3 Availability Zones."
  }
}

variable "single_nat_gateway" {
  description = "true = one NAT gateway (cheaper, dev). false = one per AZ (resilient, prod)."
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "How long to keep VPC Flow Logs in CloudWatch Logs."
  type        = number
  default     = 30
}

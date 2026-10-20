variable "region" {
  description = "AWS Region for the state bucket and IAM resources."
  type        = string
  default     = "us-east-1"
}
#
variable "state_bucket_name" {
  description = "Globally unique name for the Terraform state S3 bucket"
  type        = string
}   
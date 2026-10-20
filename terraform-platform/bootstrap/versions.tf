terraform {
  required_version = ">= 1.11.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}
#
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      project   = "terraform-platform"
      component = "bootstrap"
      managedby = "terraform"
    }
  }
}
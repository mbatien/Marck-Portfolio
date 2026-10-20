terraform {
  backend "s3" {
    bucket       = "flagship-tfstate-945360924569" # output of bootstrap/
    key          = "envs/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true 
  }
}

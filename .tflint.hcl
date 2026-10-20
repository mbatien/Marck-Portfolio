config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.32.0" # check github.com/terraform-linters/tflint-ruleset-aws for the latest
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

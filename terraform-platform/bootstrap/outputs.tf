output "state_bucket_name" {
  description = "Put this in envs/*/backend.tf and jenkins/versions.tf."
  value       = aws_s3_bucket.state.bucket
}

output "jenkins_instance_profile_name" {
  description = "Used by jenkins/ for the EC2 instance."
  value       = aws_iam_instance_profile.jenkins.name
}

output "terraform_plan_role_arn" {
  description = "PLAN_ROLE in the Jenkinsfile."
  value       = aws_iam_role.terraform_plan.arn
}

output "terraform_apply_role_arn" {
  description = "APPLY_ROLE in the Jenkinsfile."
  value       = aws_iam_role.terraform_apply.arn
}

output "account_id" {
  description = "The AWS account ID."
  value       = data.aws_caller_identity.current.account_id
}
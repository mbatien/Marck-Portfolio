output "state_bucket_name" {
  description = "Put this in envs/dev/backend.tf and envs/prod/backend.tf."
  value       = aws_s3_bucket.state.bucket
}

output "account_id" {
  description = "The AWS account ID."
  value       = data.aws_caller_identity.current.account_id
}

output "dns_name" {
  value = aws_lb.this.dns_name
}

output "arn" {
  value = aws_lb.this.arn
}

output "arn_suffix" {
  description = "Used for CloudWatch metric dimensions."
  value       = aws_lb.this.arn_suffix
}

output "security_group_id" {
  value = aws_security_group.alb.id
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.app.arn_suffix
}

output "http_listener_arn" {
  value = aws_lb_listener.http.arn
}

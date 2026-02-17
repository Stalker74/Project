output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "EC2 Instance Public IP"
  value       = aws_instance.web.public_ip
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_instance.web.public_ip}:${var.app_port}"
}

output "s3_bucket_name" {
  description = "S3 Bucket for Artifacts"
  value       = aws_s3_bucket.artifacts.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.app_logs.name
}

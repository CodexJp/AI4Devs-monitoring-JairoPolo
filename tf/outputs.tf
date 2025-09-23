# Outputs for AI4Devs Datadog Integration
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.monorepo_instance.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.monorepo_instance.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.monorepo_instance.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.unified_sg.id
}

output "datadog_role_arn" {
  description = "ARN of the Datadog IAM role"
  value       = aws_iam_role.datadog_aws_integration.arn
}

output "datadog_integration_external_id" {
  description = "External ID for Datadog integration"
  value       = datadog_integration_aws_account.datadog_integration.auth_config.aws_auth_config_role.external_id
  sensitive   = true
}

output "connection_commands" {
  description = "Commands to connect to the instance"
  value = {
    ssh         = "ssh -i ~/.ssh/AI4Devs.pem ec2-user@${aws_instance.monorepo_instance.public_ip}"
    frontend    = "http://${aws_instance.monorepo_instance.public_ip}:3000"
    backend_api = "http://${aws_instance.monorepo_instance.public_ip}:8080"
  }
}
output "security_group_id" {
    description = "ID of the security group created, to associate it with the EC2 instance in the compute module"
    value       = aws_security_group.web.id
}
output "public_ip" {
    description = "Fixed public IP (Elastic IP) associated with the EC2 instance"
    value       = aws_eip.web.public_ip
}

output "instance_id" {
    description = "ID of the created EC2 instance"
    value       = aws_instance.web.id
}
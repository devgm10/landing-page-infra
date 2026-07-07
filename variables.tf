variable "aws_region" {
    description = "AWS region where the infrastructure will be deployed"
    type        = string
    default     = "us-east-1"
}

variable "project_name" {
    description = "Project name, used to name and label resources"
    type        = string
    default     = "landing-page-gm"
}

variable "instance_type" {
    description = "Type of EC2 instance to provision"
    type        = string
    default     = "t3.small"
}

variable "my_ip" {
    description = "Own public IP in CIDR format (x.x.x.x/32) authorized for SSH. The value is defined in Terraform Cloud."
    type        = string
    sensitive   = true
}

variable "ssh_public_key" {
    description = "Content of the SSH public key for access to the instance. The value is defined in Terraform Cloud."
    type        = string
}
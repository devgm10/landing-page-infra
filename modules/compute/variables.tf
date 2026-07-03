variable "project_name" {
    description = "Project name, used to name and label resources (key pair, instance, EIP)"
    type        = string
}

variable "instance_type" {
    description = "Type of EC2 instance to provision (e.g. t3.micro)"
    type        = string
}

variable "ssh_public_key" {
    description = "Content of the SSH public key that will be registered in the key pair for access to the instance"
    type        = string
}

variable "security_group_id" {
    description = "ID of the security group (from the network module) that will be associated with the EC2 instance"
    type        = string
}
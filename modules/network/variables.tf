variable "project_name" {
    description = "Project name, used to name and label the security group"
    type        = string
}

variable "my_ip" {
    description = "Own public IP in CIDR format (e.g. x.x.x.x/32) authorized for SSH access"
    type        = string
}
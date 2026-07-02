variable "aws_region" {
    type = string
    default = "us-east-1"
}

variable "project_name" {
    type = string
    default = "landing-page-gm"
}

variable "instance_type" {
    type = string
    default = "t3.micro"
}

variable "my_ip" {
    description = "38.250.151.198/32"
    type = string
}

variable "ssh_public_key" {
    description = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL4in7l1o14PbY836sfJf83kQwn95WHO+R2uRLcO7pDR landing-page-ec2"
}
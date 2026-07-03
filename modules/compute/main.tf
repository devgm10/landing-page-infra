data "aws_ami" "ubuntu" {
    most_recent = true
    owners      = ["099720109477"]

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "deployer" {
    key_name   = "${var.project_name}-key"
    public_key = var.ssh_public_key
}

resource "aws_instance" "web" {
    ami                    = data.aws_ami.ubuntu.id
    instance_type          = var.instance_type
    key_name               = aws_key_pair.deployer.key_name
    vpc_security_group_ids  = [var.security_group_id]
    user_data              = file("${path.module}/user_data.sh")

    tags = { Name = "${var.project_name}-server" }
}

resource "aws_eip" "web" {
    instance = aws_instance.web.id
    domain   = "vpc"
    tags     = { Name = "${var.project_name}-eip" }
}
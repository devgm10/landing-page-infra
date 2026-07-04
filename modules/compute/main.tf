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
    iam_instance_profile   = aws_iam_instance_profile.ssm.name
    user_data              = file("${path.module}/user_data.sh")
    tags = { Name = "${var.project_name}-server" }
}

resource "aws_eip" "web" {
    instance = aws_instance.web.id
    domain   = "vpc"
    tags     = { Name = "${var.project_name}-eip" }
}

resource "aws_iam_role" "ssm" {
    name = "${var.project_name}-ssm-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action    = "sts:AssumeRole"
            Effect    = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ssm" {
    role       = aws_iam_role.ssm.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
    name = "${var.project_name}-ssm-profile"
    role = aws_iam_role.ssm.name
}
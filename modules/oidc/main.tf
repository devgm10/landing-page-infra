# --- OIDC Provider: registra a GitHub Actions como identidad de confianza ---
resource "aws_iam_openid_connect_provider" "github" {
    url             = "https://token.actions.githubusercontent.com"
    client_id_list  = ["sts.amazonaws.com"]
    thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# --- IAM Role que GitHub Actions asumirá (sin llaves, vía OIDC) ---
resource "aws_iam_role" "github_deploy" {
    name = "${var.project_name}-github-deploy"

    assume_role_policy = jsonencode({ 
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Federated = aws_iam_openid_connect_provider.github.arn
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
                StringEquals = {
                    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
                    "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:environment:${var.github_environment}"
                }
            }
        }]
    })
}

# --- Permisos del rol: invocar SSM sobre la instancia + leer resultado ---
resource "aws_iam_role_policy" "github_deploy" {
    name = "${var.project_name}-github-deploy-policy"
    role = aws_iam_role.github_deploy.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid    = "SendCommand"
                Effect = "Allow"
                Action = ["ssm:SendCommand"]
                Resource = [
                    "arn:aws:ec2:*:*:instance/${var.instance_id}",
                    "arn:aws:ssm:*:*:document/AWS-RunShellScript"
                ]
            },
            {
                Sid      = "ReadCommandResult"
                Effect   = "Allow"
                Action   = ["ssm:GetCommandInvocation", "ssm:ListCommandInvocations"]
                Resource = "*"
            }
        ]
    })
}
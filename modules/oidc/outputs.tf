output "github_deploy_role_arn" {
    description = "ARN of the role that GitHub Actions will assume via OIDC (for the CD workflow)"
    value       = aws_iam_role.github_deploy.arn
}
variable "project_name" {
    description = "Project name, used to name OIDC resources"
    type        = string
}

variable "github_repo" {
    description = "GitHub repository in owner/repo format authorized to assume the role"
    type        = string
}

variable "github_environment" {
    description = "Authorized GitHub Actions Environment"
    type        = string
    default     = "production"
}

variable "instance_id" {
    description = "ID of the EC2 instance on which GitHub will be able to execute SSM commands"
    type        = string
}
variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "url-shortener"
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod"
  }
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-2"
}

variable "github_oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for token.actions.githubusercontent.com"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/token\\.actions\\.githubusercontent\\.com$", var.github_oidc_provider_arn))
    error_message = "Must be the ARN of the GitHub Actions OIDC provider."
  }
}

variable "github_repo" {
  description = "GitHub repository in 'owner/name' format"
  type        = string
  default     = "Ehijizi/url-shortener"
}

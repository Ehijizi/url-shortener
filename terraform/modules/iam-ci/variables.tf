variable "name_prefix" {
  description = "Prefix for resource names (e.g. 'url-shortener-dev')"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo in 'owner/name' format. Used to scope OIDC trust."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repo))
    error_message = "github_repo must be in 'owner/name' format."
  }
}

variable "allowed_branches" {
  description = <<-EOT
    Branch patterns allowed to assume this role.
    For dev, typically ["*"] (any branch) plus pull_request.
    For prod, typically ["main"] only.
    Patterns follow GitHub OIDC subject claim format.
  EOT
  type    = list(string)
  default = ["main"]
}

variable "allow_pull_requests" {
  description = "Whether pull requests can assume this role (typically true for dev, false for prod)"
  type        = bool
  default     = false
}

variable "oidc_provider_arn" {
  description = "ARN of the existing IAM OIDC provider for token.actions.githubusercontent.com"
  type        = string
}

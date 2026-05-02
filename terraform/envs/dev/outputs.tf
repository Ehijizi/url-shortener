# Outputs exposed by this environment.

output "ci_role_arn" {
  description = "ARN of the GitHub Actions CI role. Use as 'role-to-assume' in workflows."
  value       = module.iam_ci.role_arn
}

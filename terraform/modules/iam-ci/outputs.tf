output "role_arn" {
  description = "ARN of the CI role. Use this as the role-to-assume in GitHub Actions workflows."
  value       = aws_iam_role.ci.arn
}

output "role_name" {
  description = "Name of the CI role"
  value       = aws_iam_role.ci.name
}

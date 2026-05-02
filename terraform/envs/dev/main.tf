# Module composition for the dev environment.

module "iam_ci" {
  source = "../../modules/iam-ci"

  name_prefix       = local.name_prefix
  github_repo       = var.github_repo
  oidc_provider_arn = var.github_oidc_provider_arn

  # Dev allows any branch to deploy, plus pull requests for ephemeral previews.
  # Prod (in Phase 4) will be tightened to main only with no PR access.
  allowed_branches    = ["*"]
  allow_pull_requests = true
}

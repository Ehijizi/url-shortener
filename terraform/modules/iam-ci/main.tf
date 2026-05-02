# Look up the current AWS account ID so callers don't need to pass it explicitly.
# This makes the module portable across accounts.
data "aws_caller_identity" "current" {}

# Build the list of GitHub OIDC subject claims that are allowed to assume this role.
# The subject claim format is documented at:
# https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims
locals {
  branch_subjects = [
    for branch in var.allowed_branches :
    "repo:${var.github_repo}:ref:refs/heads/${branch}"
  ]

  pr_subjects = var.allow_pull_requests ? [
    "repo:${var.github_repo}:pull_request"
  ] : []

  allowed_subjects = concat(local.branch_subjects, local.pr_subjects)
}

# Trust policy: who is allowed to assume this role.
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    # The audience claim — must be sts.amazonaws.com when using AWS-recommended
    # configuration of GitHub OIDC.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # The subject claim — restricts WHICH GitHub workflows can assume the role.
    # Without this condition, any GitHub repo could assume this role. This is
    # the single most important line in this module.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_subjects
    }
  }
}

resource "aws_iam_role" "ci" {
  name               = "${var.name_prefix}-ci"
  description        = "GitHub Actions OIDC role for ${var.github_repo} (${var.name_prefix})"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  # 1 hour is the default; we make it explicit for documentation purposes.
  max_session_duration = 3600
}

# Permissions policy: what this role is allowed to do once assumed.
# Scoped where possible to resources matching this project's name prefix.
data "aws_iam_policy_document" "ci_permissions" {
  # Lambda — manage functions for this project
  statement {
    sid    = "LambdaManagement"
    effect = "Allow"
    actions = [
      "lambda:*",
    ]
    resources = [
      "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.name_prefix}-*",
      "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:layer:${var.name_prefix}-*",
      "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:layer:${var.name_prefix}-*:*",
    ]
  }

  # Lambda needs some unscoped reads (ListFunctions etc.)
  statement {
    sid    = "LambdaList"
    effect = "Allow"
    actions = [
      "lambda:ListFunctions",
      "lambda:ListLayers",
      "lambda:GetAccountSettings",
    ]
    resources = ["*"]
  }

  # API Gateway — needs to be unscoped because the v2 API doesn't support
  # resource-level permissions on most actions, and free-tier portfolio
  # scope doesn't justify the complexity of a tag-based condition.
  statement {
    sid    = "ApiGateway"
    effect = "Allow"
    actions = [
      "apigateway:*",
    ]
    resources = ["*"]
  }

  # DynamoDB — manage tables matching the project prefix
  statement {
    sid    = "DynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:*",
    ]
    resources = [
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${var.name_prefix}-*",
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${var.name_prefix}-*/index/*",
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${var.name_prefix}-*/stream/*",
    ]
  }

  # CloudWatch Logs — Lambda log groups follow the /aws/lambda/<function-name> convention
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:*",
    ]
    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.name_prefix}-*",
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.name_prefix}-*:*",
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/${var.name_prefix}-*",
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/${var.name_prefix}-*:*",
    ]
  }

  # IAM — needed to create roles for Lambda functions, scoped to project prefix
  statement {
    sid    = "IAMRolesForServices"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:PassRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:ListPolicyVersions",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.name_prefix}-*",
    ]
  }

  # S3 — for frontend bucket and Terraform state access
  statement {
    sid    = "S3FrontendBucket"
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::${var.name_prefix}-*",
      "arn:aws:s3:::${var.name_prefix}-*/*",
    ]
  }

  # S3 state bucket — read/write the project's state path only
  statement {
    sid    = "S3TerraformState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::ehi-ci-cd-artifacts-${data.aws_caller_identity.current.account_id}",
      "arn:aws:s3:::ehi-ci-cd-artifacts-${data.aws_caller_identity.current.account_id}/url-shortener/*",
    ]
  }

  # DynamoDB state lock table
  statement {
    sid    = "DynamoDBStateLock"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
    ]
    resources = [
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/terraform-state-lock",
    ]
  }
}

resource "aws_iam_role_policy" "ci" {
  name   = "${var.name_prefix}-ci-permissions"
  role   = aws_iam_role.ci.id
  policy = data.aws_iam_policy_document.ci_permissions.json
}

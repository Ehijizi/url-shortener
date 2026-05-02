# ADR-0002: GitHub Actions authenticates to AWS via OIDC, not access keys

**Status:** Accepted
**Date:** 2026-05-01

## Context

CI/CD must run `terraform apply` and deploy Lambda code to AWS. This requires AWS credentials in the GitHub Actions environment.

## Decision

Use GitHub Actions' OIDC integration with AWS STS. Each environment gets a dedicated IAM role (`url-shortener-dev-ci`, `url-shortener-prod-ci`) whose trust policy is scoped to:

- Issuer: `token.actions.githubusercontent.com` (the existing OIDC provider in account 718780249654)
- Audience: `sts.amazonaws.com`
- Subject: limited to the `Ehijizi/url-shortener` repository, with branch restrictions per environment (dev: any branch + PRs; prod: `main` only, via environment protection rules in Phase 4)

We explicitly reject:

1. **IAM user with long-lived access keys stored in GitHub Secrets.** Standard pattern five years ago, now considered a security anti-pattern by AWS. Long-lived credentials cannot be bound to a specific repo/branch and create rotation toil.
2. **Single shared CI role across environments.** Would prevent us from using IAM-level isolation between dev and prod.

## Permissions scoping

The role is granted broad service-level permissions (Lambda, DynamoDB, API Gateway, CloudWatch, IAM, S3 for frontend) needed to manage this project's resources. Where AWS supports it (e.g. resource ARNs scoped by name prefix or tag), permissions are constrained.

This is a deliberate compromise: a fully minimal policy enumerating each action+resource is infeasible to maintain at this stage and slows iteration. Phase 4 hardening will tighten the policy further using IAM Access Analyzer's policy generation feature, which derives a least-privilege policy from observed CloudTrail activity.

## Consequences

**Positive:** No long-lived credentials anywhere. Trust is repo+branch bound. Role permissions are versioned in Git and reviewed in PRs.

**Negative:** Slightly more complex initial setup than access keys. Anyone forking the repo will need to set up their own role.

**Neutral:** The OIDC provider itself is shared with other projects in this account and managed outside of this repo (see `terraform/bootstrap/README.md`).

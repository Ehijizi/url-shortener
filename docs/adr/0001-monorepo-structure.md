# ADR-0001: Monorepo with per-environment Terraform compositions

**Status:** Accepted
**Date:** 2026-05-01

## Context

We need to host Terraform infrastructure code, multiple Lambda functions in Go, a static frontend, and CI/CD workflows. The project has two environments (dev and prod) with near-identical infrastructure but different sizing and retention policies.

## Decision

Use a single Git repository (monorepo) with the following structure:

- `terraform/modules/` — reusable building blocks
- `terraform/envs/{dev,prod}/` — per-environment compositions, each its own root module with its own remote state
- `services/<name>/` — one Go module per Lambda function

We explicitly reject:

1. **Multiple repos** (one for infra, one per service). Adds coordination overhead with no benefit at this scale.
2. **Single Terraform root with `count = var.is_prod`**. Looks DRY but makes deliberate dev/prod drift painful and increases blast radius of `terraform apply`.

## Consequences

**Positive:** Single source of truth. CI can use path filters to only run jobs affected by a change. Onboarding is "clone one repo." ADRs and runbooks live next to the code they describe.

**Negative:** CI workflows need path filters or every push triggers everything. Repo will grow over time; if it ever becomes unwieldy, a service can be extracted later (rare in practice).

**Neutral:** `terraform/envs/dev` and `terraform/envs/prod` will have near-duplicate `main.tf` files. This duplication is *intentional* — it's the seam where intentional drift between environments is expressed.

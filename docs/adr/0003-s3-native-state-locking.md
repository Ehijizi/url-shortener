# ADR-0003: S3-native state locking via use_lockfile

**Status:** Accepted
**Date:** 2026-05-02

## Context

Terraform's S3 backend has historically required a DynamoDB table to coordinate state locks between concurrent operations, because S3 lacked the strong consistency guarantees needed for safe lock implementation. As of December 2020, S3 provides strong read-after-write consistency for all operations, and the Terraform AWS provider has added native S3-based locking via the `use_lockfile = true` backend parameter. The `dynamodb_table` parameter is now deprecated.

We initially configured the dev environment with the DynamoDB-backed locking pattern (per ADR-0002) and were prompted by a deprecation warning on first apply.

## Decision

Migrate to `use_lockfile = true` and remove `dynamodb_table` from the backend configuration. The existing `terraform-state-lock` DynamoDB table remains in place but is no longer used; it is harmless (PAY_PER_REQUEST, no idle cost) and serves as a fallback should we ever need to revert.

## Consequences

**Positive:** One fewer AWS resource in the critical path. Avoids the long-tail risk of the `dynamodb_table` parameter being removed in a future provider major version. S3-native locking is now the HashiCorp-recommended default for new configurations.

**Negative:** The `terraform-state-lock` table is now orphaned. We accept this for now; it can be deleted in Phase 4 hardening once we've gained confidence in the new locking mechanism across both environments.

**Neutral:** Lock contention behaviour differs slightly — S3 conditional PUTs vs. DynamoDB conditional PutItem — but for a solo project the practical experience is identical.

## Validation

After migration:
- \`terraform init -migrate-state\` succeeded without state copying (same bucket and key path)
- \`terraform plan\` shows no drift and no deprecation warnings
- A \`<key>.tflock\` object will be created in S3 during operations and removed afterwards

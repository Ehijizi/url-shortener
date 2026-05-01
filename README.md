# URL Shortener

Production-grade serverless URL shortener on AWS. Portfolio project demonstrating senior DevOps patterns within free-tier constraints.

## Architecture

API Gateway (HTTP API) → Lambda (Go) → DynamoDB. Static frontend on S3 + CloudFront. Analytics via EventBridge → Lambda → DynamoDB aggregations.

## Status

🚧 In progress — see [docs/adr/](docs/adr/) for design decisions and [phases](#phases) below.

## Phases

- [ ] **Phase 1** — Foundations: Terraform modules, two environments, OIDC, DynamoDB design, basic Lambda + API Gateway
- [ ] **Phase 2** — Doing it properly: collision handling, validation, rate limiting, WAF, frontend
- [ ] **Phase 3** — Observability and analytics: structured logging, X-Ray, EventBridge analytics, dashboards, canary
- [ ] **Phase 4** — Hardening and chaos: promotion workflow, integration/smoke tests, backup drill, chaos experiment, runbooks

## Repo layout

\`\`\`
terraform/   Infrastructure as code (modules + per-env composition)
services/    Lambda functions (Go, one module per function)
frontend/    Static site (added in Phase 2)
tests/       Integration + smoke tests
docs/        ADRs and runbooks
\`\`\`

## Caveats / scope

This is a portfolio project. Production differences explicitly out of scope and noted in [docs/adr/](docs/adr/).

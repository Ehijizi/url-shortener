# Bootstrap resources (intentionally unmanaged by Terraform)

The following AWS resources are required *before* Terraform can run, and are therefore created manually:

| Resource | Name | Purpose |
|---|---|---|
| S3 bucket | `ehi-ci-cd-artifacts-718780249654` | Stores Terraform remote state files |
| DynamoDB table | `terraform-state-lock` | Prevents concurrent `terraform apply` runs from corrupting state |
| IAM OIDC provider | `token.actions.githubusercontent.com` | Allows GitHub Actions to assume IAM roles via OIDC (no long-lived keys) |

## Why these are not in Terraform

These resources have a chicken-and-egg relationship with Terraform itself: Terraform needs the state bucket and lock table to *exist* before it can run with the S3 backend that uses them. Bootstrapping them with local state and then migrating is possible but introduces a fragile transition. We accept the small cost of manual creation in exchange for clearer ownership.

## Recreating them

Should this account ever be rebuilt:

\`\`\`bash
# State bucket (create with versioning enabled and public access blocked)
aws s3api create-bucket \
  --bucket ehi-ci-cd-artifacts-718780249654 \
  --region eu-west-2 \
  --create-bucket-configuration LocationConstraint=eu-west-2

aws s3api put-bucket-versioning \
  --bucket ehi-ci-cd-artifacts-718780249654 \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block \
  --bucket ehi-ci-cd-artifacts-718780249654 \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Lock table
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-2
\`\`\`

The OIDC provider is reused from a separate project (Ehi-CI-CD) and is also intentionally unmanaged here so that multiple projects can share it.

## State layout

Each environment uses a separate state file under a key prefix:

- \`s3://ehi-ci-cd-artifacts-718780249654/url-shortener/dev/terraform.tfstate\`
- \`s3://ehi-ci-cd-artifacts-718780249654/url-shortener/prod/terraform.tfstate\`

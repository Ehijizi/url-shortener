terraform {
  # Constraint reflects the version this config has been tested with.
  # Bump deliberately when adopting newer features.
  required_version = ">= 1.14, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

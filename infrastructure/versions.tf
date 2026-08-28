terraform {
  # >= 1.10.0 (raised from 1.5.0 by 4.2-setup-remote-backend) is required for
  # the S3 backend's native `use_lockfile` state locking, used instead of a
  # DynamoDB lock table -- see infrastructure/backend.tf.
  required_version = ">= 1.10.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

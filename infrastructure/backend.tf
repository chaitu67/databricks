terraform {
  backend "s3" {
    bucket       = "databricks-tfstate-065790771695"
    key          = "databricks/infrastructure/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true # S3-native locking (Terraform >= 1.10) -- no DynamoDB table
    encrypt      = true
  }
}

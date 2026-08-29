# Provisions one Unity Catalog catalog backed by external S3 storage (a dedicated
# bucket + IAM role + storage credential + external location per catalog), plus its
# schemas. Does NOT create or assign a metastore -- this account already has one
# auto-provisioned and auto-assigned to every workspace (Databricks manages this by
# default for newer accounts); every UC resource below defaults to the workspace's
# current metastore assignment when metastore_id is left unset.
#
# Uses the databricks provider's own `databricks_aws_unity_catalog_*` data sources
# to generate the IAM trust/permissions policies (the Unity-Catalog-specific
# analogues of modules/workspace's `databricks_aws_*` data sources for the
# cross-account role), rather than hand-maintained policy JSON.

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "catalog_storage" {
  bucket        = var.bucket_name
  force_destroy = var.bucket_force_destroy
}

resource "aws_s3_bucket_public_access_block" "catalog_storage" {
  bucket                  = aws_s3_bucket.catalog_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "databricks_aws_unity_catalog_assume_role_policy" "this" {
  aws_account_id = data.aws_caller_identity.current.account_id
  role_name      = var.storage_credential_role_name
  external_id    = var.databricks_account_id
}

resource "aws_iam_role" "unity_catalog" {
  name               = var.storage_credential_role_name
  assume_role_policy = data.databricks_aws_unity_catalog_assume_role_policy.this.json
  tags               = { Name = var.storage_credential_role_name }
}

data "databricks_aws_unity_catalog_policy" "this" {
  aws_account_id = data.aws_caller_identity.current.account_id
  bucket_name    = var.bucket_name
  role_name      = var.storage_credential_role_name
}

resource "aws_iam_role_policy" "unity_catalog" {
  name   = "${var.storage_credential_role_name}-policy"
  role   = aws_iam_role.unity_catalog.id
  policy = data.databricks_aws_unity_catalog_policy.this.json
}

# Same IAM-eventual-consistency rationale as modules/workspace's iam_propagation:
# Databricks validates the role by actually assuming it when the storage credential
# is created, which can fail for a few seconds right after the policy is attached.
resource "time_sleep" "iam_propagation" {
  depends_on      = [aws_iam_role_policy.unity_catalog]
  create_duration = "30s"
}

resource "databricks_storage_credential" "this" {
  name = var.storage_credential_role_name
  aws_iam_role {
    role_arn    = aws_iam_role.unity_catalog.arn
    external_id = var.databricks_account_id
  }
  depends_on = [time_sleep.iam_propagation]
}

resource "databricks_external_location" "this" {
  name            = "${var.name}-external-location"
  url             = "s3://${aws_s3_bucket.catalog_storage.bucket}/${var.name}"
  credential_name = databricks_storage_credential.this.name
}

resource "databricks_catalog" "this" {
  name         = var.name
  comment      = var.comment
  storage_root = databricks_external_location.this.url
}

resource "databricks_schema" "this" {
  for_each     = toset(var.schemas)
  catalog_name = databricks_catalog.this.name
  name         = each.value
}

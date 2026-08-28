# Provisions one new Databricks-on-AWS workspace with a Databricks-managed
# VPC (Databricks creates and manages the VPC inside this AWS account --
# no pre-existing VPC/subnets required). Customer-managed VPC is not
# implemented here; see the 5.1-create-workspace skill's SKILL.md if that's
# needed instead.
#
# Uses the databricks provider's own `databricks_aws_*` data sources to
# generate the IAM trust policy, IAM permissions policy, and S3 bucket
# policy Databricks requires, rather than hand-maintained policy JSON --
# these stay correct as Databricks' requirements evolve.

data "databricks_aws_assume_role_policy" "this" {
  provider    = databricks.mws
  external_id = var.databricks_account_id
}

resource "aws_iam_role" "cross_account" {
  name               = var.cross_account_role_name
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
  tags               = { Name = var.cross_account_role_name }
}

data "databricks_aws_crossaccount_policy" "this" {
  provider = databricks.mws
}

resource "aws_iam_role_policy" "cross_account" {
  name   = "${var.cross_account_role_name}-policy"
  role   = aws_iam_role.cross_account.id
  policy = data.databricks_aws_crossaccount_policy.this.json
}

# IAM is eventually consistent -- Databricks validates the cross-account role by
# actually assuming it when databricks_mws_credentials is created, which can fail
# with "Failed credential validation checks" if that happens right after the role
# policy is attached. This wait absorbs that propagation delay.
resource "time_sleep" "iam_propagation" {
  depends_on      = [aws_iam_role_policy.cross_account]
  create_duration = "30s"
}

resource "aws_s3_bucket" "root_storage" {
  bucket        = var.root_bucket
  force_destroy = var.root_bucket_force_destroy
}

resource "aws_s3_bucket_public_access_block" "root_storage" {
  bucket                  = aws_s3_bucket.root_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "databricks_aws_bucket_policy" "this" {
  provider = databricks.mws
  bucket   = aws_s3_bucket.root_storage.bucket
}

resource "aws_s3_bucket_policy" "root_storage" {
  bucket = aws_s3_bucket.root_storage.id
  policy = data.databricks_aws_bucket_policy.this.json
}

resource "databricks_mws_credentials" "this" {
  provider         = databricks.mws
  account_id       = var.databricks_account_id
  credentials_name = "${var.deployment_name}-credentials"
  role_arn         = aws_iam_role.cross_account.arn
  depends_on       = [time_sleep.iam_propagation]
}

resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.mws
  account_id                 = var.databricks_account_id
  storage_configuration_name = "${var.deployment_name}-storage"
  bucket_name                = aws_s3_bucket.root_storage.bucket
}

resource "databricks_mws_workspaces" "this" {
  provider       = databricks.mws
  account_id     = var.databricks_account_id
  workspace_name = var.display_name
  aws_region     = var.aws_region
  pricing_tier   = var.pricing_tier
  # deployment_name intentionally omitted: it errors with "Deployment name
  # cannot be used until a deployment name prefix is defined" on accounts
  # that don't have one configured (an account-level setting only Databricks
  # can set). Omitting it lets Databricks auto-assign the URL (the
  # dbc-<random>.cloud.databricks.com pattern) -- read it back from the
  # workspace_url output after apply.

  credentials_id           = databricks_mws_credentials.this.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id

  depends_on = [aws_s3_bucket_policy.root_storage, aws_iam_role_policy.cross_account]
}

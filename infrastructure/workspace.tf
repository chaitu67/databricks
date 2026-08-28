# Provisions one new Databricks-on-AWS workspace with a Databricks-managed
# VPC (Databricks creates and manages the VPC inside this AWS account --
# no pre-existing VPC/subnets required). Customer-managed VPC is not
# implemented here; see SKILL.md if that's needed instead.
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
  name               = var.new_workspace_cross_account_role_name
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
  tags               = { Name = var.new_workspace_cross_account_role_name }
}

data "databricks_aws_crossaccount_policy" "this" {
  provider = databricks.mws
}

resource "aws_iam_role_policy" "cross_account" {
  name   = "${var.new_workspace_cross_account_role_name}-policy"
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
  bucket        = var.new_workspace_root_bucket
  force_destroy = var.new_workspace_root_bucket_force_destroy
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
  credentials_name = "${var.new_workspace_deployment_name}-credentials"
  role_arn         = aws_iam_role.cross_account.arn
  depends_on       = [time_sleep.iam_propagation]
}

resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.mws
  account_id                 = var.databricks_account_id
  storage_configuration_name = "${var.new_workspace_deployment_name}-storage"
  bucket_name                = aws_s3_bucket.root_storage.bucket
}

resource "databricks_mws_workspaces" "this" {
  provider       = databricks.mws
  account_id     = var.databricks_account_id
  workspace_name = var.new_workspace_name
  aws_region     = var.new_workspace_aws_region
  pricing_tier   = var.new_workspace_pricing_tier
  # deployment_name intentionally omitted: it errors with "Deployment name
  # cannot be used until a deployment name prefix is defined" on accounts
  # that don't have one configured (an account-level setting only Databricks
  # can set). Omitting it lets Databricks auto-assign the URL (the
  # dbc-<random>.cloud.databricks.com pattern) -- read it back from the
  # new_workspace_url output after apply.

  credentials_id           = databricks_mws_credentials.this.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id

  depends_on = [aws_s3_bucket_policy.root_storage, aws_iam_role_policy.cross_account]
}

variable "new_workspace_name" {
  description = "Human-readable name for the new workspace (shown in the Account Console)."
  type        = string
}

variable "new_workspace_deployment_name" {
  description = "Naming prefix for this workspace's Databricks account-level resources (credentials/storage config names) -- not the URL. The actual workspace URL is auto-assigned by Databricks (see the new_workspace_url output) unless this account has a deployment name prefix configured, which most don't."
  type        = string
}

variable "new_workspace_aws_region" {
  description = "AWS region to deploy the new workspace into."
  type        = string
  default     = "us-east-1"
}

variable "new_workspace_root_bucket" {
  description = "Name of the new S3 bucket used as the workspace's DBFS root. Must be globally unique across ALL of S3, not just this AWS account."
  type        = string
}

variable "new_workspace_root_bucket_force_destroy" {
  description = "Allow `terraform destroy` to delete this bucket even if it still has objects in it. Defaults to false (AWS's own safe default); set true only for a disposable workshop/test workspace where losing the data on teardown is fine."
  type        = bool
  default     = false
}

variable "new_workspace_cross_account_role_name" {
  description = "Name of the IAM role Databricks assumes to manage EC2/networking resources in this AWS account for the new workspace."
  type        = string
  default     = "databricks-crossaccount-role"
}

variable "new_workspace_pricing_tier" {
  description = "Databricks pricing tier for the new workspace: STANDARD, PREMIUM, or ENTERPRISE."
  type        = string
  default     = "PREMIUM"
}

output "new_workspace_url" {
  description = "URL of the newly created workspace, once databricks_mws_workspaces reports RUNNING. Auto-assigned by Databricks (deployment_name is intentionally not set -- see workspace.tf)."
  value       = databricks_mws_workspaces.this.workspace_url
}

output "new_workspace_status" {
  value = databricks_mws_workspaces.this.workspace_status
}

# Provisions one serverless-only Databricks-on-AWS workspace: compute_mode = "SERVERLESS"
# means Databricks runs all compute in its own compute plane and manages default storage
# itself -- no cross-account IAM role, no root S3 bucket, and no customer- or
# Databricks-managed VPC/NAT gateway/security groups get created in this AWS account at all.
# credentials_id, storage_configuration_id, and network_id must NOT be set when compute_mode
# is SERVERLESS (the provider rejects the apply if they are). This is the whole reason this
# is a separate module from modules/workspace rather than a variant of it -- that module's
# very first resources are the IAM role and S3 bucket this one deliberately has none of.
resource "databricks_mws_workspaces" "this" {
  provider       = databricks.mws
  account_id     = var.databricks_account_id
  workspace_name = var.workspace_name
  aws_region     = var.aws_region
  compute_mode   = "SERVERLESS"
  pricing_tier   = var.pricing_tier
}

# Account-admin status alone does not grant workspace access -- each principal must be
# explicitly assigned per workspace. Declared here (instead of a manual
# `databricks account workspace-assignment update` step) so workspace access is
# version-controlled and PR-reviewable, same as modules/workspace.
data "databricks_user" "admins" {
  for_each  = toset(var.admin_emails)
  provider  = databricks.mws
  user_name = each.value
}

resource "databricks_mws_permission_assignment" "admins" {
  for_each     = toset(var.admin_emails)
  provider     = databricks.mws
  workspace_id = databricks_mws_workspaces.this.workspace_id
  principal_id = data.databricks_user.admins[each.key].id
  permissions  = ["ADMIN"]
}

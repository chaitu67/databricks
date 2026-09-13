# One serverless-only Databricks-on-AWS workspace per entry in var.serverless_workspaces
# (see variables.tf) -- add a new one by adding an entry to the committed
# serverless_workspaces.auto.tfvars, never by editing this file or any CI workflow.
# See modules/serverless_workspace/main.tf for why this is a distinct module from
# modules/workspace rather than a flag on it: compute_mode = SERVERLESS workspaces create
# no AWS resources (no IAM role, no S3 bucket, no VPC) at all.
module "serverless_workspace" {
  source   = "./modules/serverless_workspace"
  for_each = var.serverless_workspaces

  providers = {
    databricks.mws = databricks.mws
  }

  databricks_account_id = var.databricks_account_id
  workspace_name        = each.value.workspace_name
  aws_region            = coalesce(each.value.aws_region, var.aws_region)
  pricing_tier          = each.value.pricing_tier
  admin_emails          = each.value.admin_emails
}

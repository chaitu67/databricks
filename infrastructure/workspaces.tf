# One Databricks-on-AWS workspace per entry in var.workspaces (see variables.tf) --
# add a new workspace by adding an entry to the committed workspaces.auto.tfvars,
# never by editing this file or any CI workflow.
module "workspace" {
  source   = "./modules/workspace"
  for_each = var.workspaces

  providers = {
    databricks.mws = databricks.mws
  }

  databricks_account_id     = var.databricks_account_id
  display_name              = each.value.display_name
  deployment_name           = coalesce(each.value.deployment_name, each.key)
  aws_region                = coalesce(each.value.aws_region, var.aws_region)
  root_bucket               = each.value.root_bucket
  root_bucket_force_destroy = each.value.root_bucket_force_destroy
  cross_account_role_name   = coalesce(each.value.cross_account_role_name, "databricks-${each.key}-crossaccount")
  pricing_tier              = each.value.pricing_tier
  admin_emails              = each.value.admin_emails
}

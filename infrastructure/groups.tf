# One account-level Databricks group (with members) per entry in var.groups (see
# variables.tf) -- add a new group by adding an entry to the committed
# groups.auto.tfvars, never by editing this file or any CI workflow. Same
# providers = {} idiom as workspaces.tf: group creation/membership is
# account-scoped, not workspace-scoped.
module "group" {
  source   = "./modules/group"
  for_each = var.groups

  providers = {
    databricks.mws = databricks.mws
  }

  name          = each.key
  member_emails = each.value.member_emails
}

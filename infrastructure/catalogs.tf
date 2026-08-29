# One Unity Catalog catalog (external S3-backed storage) per entry in var.catalogs
# (see variables.tf) -- add a new catalog by adding an entry to the committed
# catalogs.auto.tfvars, never by editing this file or any CI workflow. Unlike
# workspaces.tf, no `providers = {}` block is needed: this module only uses the
# plain default databricks/aws providers (catalogs are workspace-scoped, not
# account-scoped).
module "catalog" {
  source   = "./modules/catalog"
  for_each = var.catalogs

  databricks_account_id        = var.databricks_account_id
  name                         = each.key
  comment                      = each.value.comment
  bucket_name                  = each.value.bucket_name
  bucket_force_destroy         = each.value.bucket_force_destroy
  storage_credential_role_name = coalesce(each.value.storage_credential_role_name, "databricks-uc-${each.key}-storage")
  schemas                      = each.value.schemas
}

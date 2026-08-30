# Scaffolded by scripts/add-pattern01-unit.sh for unit_key "pharmacy_dev".
# Workspace/catalog/role data comes entirely from
# var.pattern01_units["pharmacy_dev"] (pattern01_units.auto.tfvars) -- never
# edit this file to change what gets created, except to add/update the
# extra_grants argument below (cross-unit grants targeting this unit's
# catalogs -- see infrastructure/modules/organization/01-pattern's
# variables.tf).
module "pattern01_unit_pharmacy_dev" {
  source = "./modules/organization/01-pattern"

  providers = {
    databricks.mws = databricks.mws
  }

  databricks_account_id = var.databricks_account_id
  auth_type             = var.databricks_auth_type
  client_id             = var.databricks_client_id
  workspace             = var.pattern01_units["pharmacy_dev"].workspace
  catalogs              = var.pattern01_units["pharmacy_dev"].catalogs

  # extra_grants = [
  #   {
  #     catalog_key = "..."
  #     group_name  = module.pattern01_unit_<other_key>.group_names["..."].reader
  #     privileges  = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  #   },
  # ]
}

# "01-pattern" organization units -- one Databricks workspace per business
# unit/department x environment tier, per docs/organization/01-pattern/pattern-definition.md.
# Add a new unit_key by running scripts/add-pattern01-unit.sh <unit_key> first (scaffolds its
# module block), then adding its entry here. A brand-new unit's first submission leaves
# workspace.host null and catalogs {} -- host is only knowable once the workspace is actually
# created and RUNNING (see 6.4-deploy-organization's "two-phase reality"); catalogs follow in a
# second PR once that's confirmed.
pattern01_units = {
  "pharmacy_dev" = {
    workspace = {
      display_name              = "pharmacy-dev"
      deployment_name           = "pharmacy-dev"
      aws_region                = "us-east-1"
      root_bucket               = "pharmacy-dev-dbfs-root-6cf95bdd"
      root_bucket_force_destroy = false
      cross_account_role_name   = "databricks-pharmacy-dev-crossaccount"
      pricing_tier              = "PREMIUM"
      admin_emails              = ["datagaiinc@gmail.com"]
      host                      = null
    }
    catalogs = {}
  }
  "retail_dev" = {
    workspace = {
      display_name              = "retail-dev"
      deployment_name           = "retail-dev"
      aws_region                = "us-east-1"
      root_bucket               = "retail-dev-dbfs-root-3f2a9c17"
      root_bucket_force_destroy = false
      cross_account_role_name   = "databricks-retail-dev-crossaccount"
      pricing_tier              = "PREMIUM"
      admin_emails              = ["datagaiinc@gmail.com"]
      host                      = null
    }
    catalogs = {}
  }
}

# Unity Catalog catalogs to create -- one map entry each. Add a new catalog by adding an
# entry here (name/bucket/schemas -- none of this is secret), open a PR, merge. Terraform
# auto-loads this file locally and in CI: no TF_VAR_, no `gh variable set`, no workflow YAML
# edit needed for a new catalog.
#
# All catalogs land in whichever workspace the default `databricks` provider currently
# targets (see terraform.tfvars: databricks_profile = "WORKSHOP" -> workshop-workspace).
#
# environment = "prod" entries have their key pattern-enforced (<env>_<domain>[_<subdomain>]) --
# see docs/naming-conventions.md. "analytics" predates that convention and stays "dev" (not
# enforced, not renamed) unless deliberately reclassified as prod later.
catalogs = {
  "analytics" = {
    environment                  = "dev"
    comment                      = "General-purpose analytics catalog"
    bucket_name                  = "analytics-uc-storage-22fb6946"
    bucket_force_destroy         = false
    storage_credential_role_name = "databricks-uc-analytics-storage"
    schemas                      = ["bronze", "silver", "gold"]
  }
}

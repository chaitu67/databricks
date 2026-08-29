terraform {
  required_providers {
    # No configuration_aliases needed here, same reasoning as modules/catalog --
    # volumes are workspace-scoped (Unity Catalog REST API on the workspace
    # itself), not account-scoped, so this module only uses the plain default
    # `databricks` provider, inherited automatically from the root module.
    databricks = {
      source = "databricks/databricks"
    }
  }
}

terraform {
  required_providers {
    # configuration_aliases is mandatory here, same as modules/workspace: group
    # creation and membership are account-level operations (accounts.cloud.databricks.com),
    # not workspace-scoped, so this module needs the root module's databricks.mws
    # provider instance passed in explicitly.
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.mws]
    }
  }
}

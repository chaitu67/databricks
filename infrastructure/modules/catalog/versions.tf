terraform {
  required_providers {
    # No configuration_aliases needed here, unlike modules/workspace -- catalogs,
    # schemas, storage credentials, and external locations are workspace-scoped
    # (Unity Catalog REST API on the workspace itself), not account-scoped, so this
    # module only uses the plain default `databricks`/`aws` providers, inherited
    # automatically from the root module.
    databricks = {
      source = "databricks/databricks"
    }
    aws = {
      source = "hashicorp/aws"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

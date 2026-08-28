terraform {
  required_providers {
    # configuration_aliases is mandatory here: it's what lets the root module
    # pass its account-level `databricks.mws` provider instance into this
    # module's `databricks.mws` references below.
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.mws]
    }
    aws = {
      source = "hashicorp/aws"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

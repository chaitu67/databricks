terraform {
  required_providers {
    # This module needs TWO databricks provider configurations:
    #   - `databricks.mws` (account-scoped: creating the workspace itself,
    #     account-level groups) -- configuration_aliases is mandatory here so
    #     the caller can pass its one shared account-level provider instance
    #     in, same idiom as modules/workspace and modules/group.
    #   - `databricks.this_unit` (workspace-scoped: catalogs, schemas, storage
    #     credentials, external locations, grants) -- self-declared in
    #     providers.tf, NOT received from the caller. Verified empirically that
    #     Terraform permits a module to declare its own provider and still be
    #     called from more than one separately-named module block (see
    #     providers.tf's own comment for the exact restriction this doesn't
    #     run into).
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

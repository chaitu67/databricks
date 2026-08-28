# Databricks account-wide settings, shared by every workspace in workspaces.auto.tfvars.
# Not secret (a UUID, grants no access by itself) -- safe to commit; auto-loaded by
# Terraform locally and in CI, no TF_VAR_/repo-variable wiring needed.
databricks_account_id = "2c51201c-6fce-46c8-9807-2ae29c4187c3"

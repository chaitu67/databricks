# Databricks workspaces to create -- one map entry each. Add a new workspace by
# adding an entry here (name/region/bucket/tier -- none of this is secret), open a
# PR, merge. Terraform auto-loads this file locally and in CI: no TF_VAR_, no
# `gh variable set`, no workflow YAML edit needed for a new workspace.
workspaces = {
  "workshop-workspace" = {
    display_name              = "workshop-workspace"
    deployment_name           = "workshop-workspace"
    aws_region                = "us-east-1"
    root_bucket               = "workshop-workspace-dbfs-root-aea9b52e"
    root_bucket_force_destroy = false
    cross_account_role_name   = "databricks-workshop-workspace-crossaccount"
    pricing_tier              = "PREMIUM"
  }
}

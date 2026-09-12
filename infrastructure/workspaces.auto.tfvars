# Databricks workspaces to create -- one map entry each. Add a new workspace by
# adding an entry here (name/region/bucket/tier -- none of this is secret), open a
# PR, merge. Terraform auto-loads this file locally and in CI: no TF_VAR_, no
# `gh variable set`, no workflow YAML edit needed for a new workspace.
workspaces = {}

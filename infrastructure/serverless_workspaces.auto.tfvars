# Serverless-only Databricks-on-AWS workspaces to create -- one map entry each. Add a new
# workspace by adding an entry here (name/region/tier -- none of this is secret), open a PR,
# merge. Terraform auto-loads this file locally and in CI: no TF_VAR_, no `gh variable set`,
# no workflow YAML edit needed for a new serverless workspace.
#
# compute_mode = SERVERLESS (see modules/serverless_workspace) means no cross-account IAM
# role, root S3 bucket, or VPC gets created in AWS for these -- Databricks manages default
# storage and runs all compute in its own compute plane.
serverless_workspaces = {
  "org-bu1-us-east-1-dev" = {
    workspace_name = "org-bu1-us-east-1-dev"
    aws_region     = "us-east-1"
    pricing_tier   = "PREMIUM"
    admin_emails   = ["datagaiinc@gmail.com"]
  }
}

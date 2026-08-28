# Account-level Databricks provider, used only by resources that operate on
# the Databricks *account* (accounts.cloud.databricks.com) rather than a
# single workspace -- e.g. creating a new workspace itself. Distinct from
# the default `databricks` provider in providers.tf, which talks to one
# already-existing workspace.
#
# Local use: an ACCOUNT ADMIN runs, in their own terminal or via the
# 5.1-create-workspace skill's deploy.sh (which triggers this automatically):
#   databricks auth login --host https://accounts.cloud.databricks.com \
#     --account-id <databricks_account_id> --profile ACCOUNT
# This opens a browser for OAuth login and saves the result to the profile
# named by databricks_account_profile below.
#
# CI use (GitHub Actions, via 04-github-cicd/4.3-configure-github-oidc): same
# databricks_auth_type/databricks_client_id vars as the default provider in
# providers.tf -- profile is left null under github-oidc so it doesn't try to
# load a local ~/.databrickscfg profile that doesn't exist on a CI runner.
# The federation policy trusting this service principal must include a
# subject covering whatever triggers this (pull_request / environment:<name>)
# for account-level calls to succeed, same as workspace-level ones.
provider "databricks" {
  alias      = "mws"
  auth_type  = var.databricks_auth_type
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  client_id  = var.databricks_client_id
  profile    = var.databricks_auth_type == null ? var.databricks_account_profile : null
}

variable "databricks_account_id" {
  description = "Databricks account ID (Account Console > top right, or `cat ~/.databrickscfg` after any account-level login). Required to create a workspace."
  type        = string
}

variable "databricks_account_profile" {
  description = "~/.databrickscfg profile used for account-level auth. Created by `databricks auth login --host https://accounts.cloud.databricks.com --account-id <id> --profile <this>`."
  type        = string
  default     = "ACCOUNT"
}

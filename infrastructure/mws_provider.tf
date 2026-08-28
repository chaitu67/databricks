# Account-level Databricks provider, used only by resources that operate on
# the Databricks *account* (accounts.cloud.databricks.com) rather than a
# single workspace -- e.g. creating a new workspace itself. Distinct from
# the default `databricks` provider in providers.tf, which talks to one
# already-existing workspace.
#
# Auth: an ACCOUNT ADMIN must run, in their own terminal or via the
# 3.3-create-workspace skill's deploy.sh (which triggers this automatically):
#   databricks auth login --host https://accounts.cloud.databricks.com \
#     --account-id <databricks_account_id> --profile ACCOUNT
# This opens a browser for OAuth login and saves the result to the profile
# named by databricks_account_profile below.
provider "databricks" {
  alias      = "mws"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  profile    = var.databricks_account_profile
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

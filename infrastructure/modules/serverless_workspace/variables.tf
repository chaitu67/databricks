variable "databricks_account_id" {
  description = "Databricks account ID (shared across all workspace instances of this module)."
  type        = string
}

variable "workspace_name" {
  description = "Human-readable name for the workspace (shown in the Account Console). Also becomes the workspace_name argument on databricks_mws_workspaces -- unlike modules/workspace, there is no separate deployment_name here, since a serverless workspace has no cross-account-role/storage-config names to prefix."
  type        = string
}

variable "aws_region" {
  description = "AWS region to create this workspace's account-level record in. No AWS resources are actually created in this region (or anywhere else) by this module -- compute_mode = SERVERLESS means Databricks runs everything in its own compute plane."
  type        = string
}

variable "pricing_tier" {
  description = "Databricks pricing tier for this workspace: STANDARD, PREMIUM, or ENTERPRISE."
  type        = string
  default     = "PREMIUM"
}

variable "admin_emails" {
  description = "Account user emails to assign ADMIN access to this workspace. Account-admin status alone does NOT grant workspace access -- a principal must be explicitly assigned per workspace, which is what this manages (declaratively, instead of a manual `databricks account workspace-assignment update` step)."
  type        = list(string)
  default     = []
}

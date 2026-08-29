variable "databricks_account_id" {
  description = "Databricks account ID (shared across all workspace instances of this module)."
  type        = string
}

variable "display_name" {
  description = "Human-readable name for the workspace (shown in the Account Console)."
  type        = string
}

variable "deployment_name" {
  description = "Naming prefix for this workspace's Databricks account-level resources (credentials/storage config names) -- not the URL. The actual workspace URL is auto-assigned by Databricks (see the workspace_url output) unless this account has a deployment name prefix configured, which most don't."
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy this workspace into."
  type        = string
}

variable "root_bucket" {
  description = "Name of the S3 bucket used as this workspace's DBFS root. Must be globally unique across ALL of S3, not just this AWS account."
  type        = string
}

variable "root_bucket_force_destroy" {
  description = "Allow `terraform destroy` to delete this bucket even if it still has objects in it. Defaults to false (AWS's own safe default); set true only for a disposable workshop/test workspace where losing the data on teardown is fine."
  type        = bool
  default     = false
}

variable "cross_account_role_name" {
  description = "Name of the IAM role Databricks assumes to manage EC2/networking resources in this AWS account for this workspace."
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

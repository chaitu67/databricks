variable "aws_region" {
  description = "AWS region to deploy Databricks-related infrastructure into."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to authenticate with. Leave null to use the default credential chain."
  type        = string
  default     = null
}

variable "databricks_profile" {
  description = "~/.databrickscfg profile for the default (non-account) Databricks provider. Populated by `databricks auth login` (OAuth) via the 3.2.2-authenticate-databricks skill — the 'DEFAULT' profile is used unless a workspace host/token override below is set."
  type        = string
  default     = "DEFAULT"
}

variable "databricks_host" {
  description = "Databricks workspace URL, e.g. https://<workspace>.cloud.databricks.com. Only needed to override the profile above with explicit host+token (PAT) auth; leave null to use databricks_profile."
  type        = string
  default     = null
}

variable "databricks_token" {
  description = "Databricks personal access token, only used if databricks_host is also set. Pass via TF_VAR_databricks_token or a gitignored .tfvars file — never commit it. Leave null to use databricks_profile (OAuth) instead."
  type        = string
  sensitive   = true
  default     = null
}

variable "databricks_auth_type" {
  description = "Explicit Databricks provider auth type override. Set to \"github-oidc\" for GitHub Actions workload identity federation (paired with databricks_client_id below; no stored secret) — set via TF_VAR_databricks_auth_type in the GitHub Actions workflow, per the 04-github-cicd skill group. Leave null for local use, which falls back to databricks_profile (or databricks_host/databricks_token) exactly as before this variable existed."
  type        = string
  default     = null
}

variable "databricks_client_id" {
  description = "Application ID (client ID -- not a secret) of the Databricks service principal used for GitHub Actions workload identity federation. Only read when databricks_auth_type = \"github-oidc\"; set via TF_VAR_databricks_client_id (a plain GitHub Actions repo variable, since it grants no access by itself)."
  type        = string
  default     = null
}

variable "workspaces" {
  description = "Map of Databricks workspaces to create, keyed by a short slug (used to default deployment_name/cross_account_role_name and as the module instance key). Values come from the committed workspaces.auto.tfvars -- add an entry there to provision a new workspace; no CI/workflow changes needed."
  type = map(object({
    display_name              = string
    deployment_name           = optional(string)
    aws_region                = optional(string)
    root_bucket               = string
    root_bucket_force_destroy = optional(bool, false)
    cross_account_role_name   = optional(string)
    pricing_tier              = optional(string, "PREMIUM")
    admin_emails              = optional(list(string), [])
  }))
  default = {}
}

variable "catalogs" {
  description = "Map of Unity Catalog catalogs to create, keyed by a short slug (the catalog name and the module instance key). Values come from the committed catalogs.auto.tfvars -- add an entry there to provision a new catalog; no CI/workflow changes needed. Each catalog gets its own dedicated S3 bucket + IAM role + storage credential + external location."
  type = map(object({
    comment                      = optional(string)
    bucket_name                  = string
    bucket_force_destroy         = optional(bool, false)
    storage_credential_role_name = optional(string)
    schemas                      = optional(list(string), [])
  }))
  default = {}
}

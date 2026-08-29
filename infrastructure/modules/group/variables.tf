variable "name" {
  description = "Account-level Databricks group display name."
  type        = string
}

variable "member_emails" {
  description = "Email addresses of existing Databricks account users to add as members of this group. Users must already exist in this Databricks account -- this module only looks them up (via the databricks_user data source), never provisions them."
  type        = list(string)
  default     = []
}

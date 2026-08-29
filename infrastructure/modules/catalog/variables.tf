variable "databricks_account_id" {
  description = "Databricks account ID -- reused as the storage credential IAM role's external_id, same idiom as modules/workspace's cross-account role."
  type        = string
}

variable "name" {
  description = "Unity Catalog catalog name."
  type        = string
}

variable "comment" {
  description = "Optional comment/description for the catalog."
  type        = string
  default     = null
}

variable "bucket_name" {
  description = "Name of the S3 bucket backing this catalog's external storage location. Must be globally unique across ALL of S3, not just this AWS account."
  type        = string
}

variable "bucket_force_destroy" {
  description = "Allow `terraform destroy` to delete this bucket even if it still has objects in it. Defaults to false (AWS's own safe default); set true only for a disposable/test catalog where losing the data on teardown is fine."
  type        = bool
  default     = false
}

variable "storage_credential_role_name" {
  description = "Name of the IAM role Databricks assumes to access this catalog's S3 bucket via Unity Catalog."
  type        = string
}

variable "schemas" {
  description = "Schema names to create inside this catalog."
  type        = list(string)
  default     = []
}

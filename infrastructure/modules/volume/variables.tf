variable "catalog_name" {
  description = "Name of the Unity Catalog catalog this volume belongs to. Must already exist (created via 5.2-create-unity-catalog)."
  type        = string
}

variable "schema_name" {
  description = "Name of the schema within catalog_name this volume belongs to. Must already exist in that catalog's schemas list (also from 5.2-create-unity-catalog)."
  type        = string
}

variable "name" {
  description = "Volume name -- unique within catalog_name.schema_name, not globally."
  type        = string
}

variable "volume_type" {
  description = "\"MANAGED\" (default -- Databricks stores the volume's files under the owning schema's managed storage location automatically, no separate bucket/credential needed) or \"EXTERNAL\" (storage_location must already be covered by a registered external location's storage credential)."
  type        = string
  default     = "MANAGED"

  validation {
    condition     = contains(["MANAGED", "EXTERNAL"], var.volume_type)
    error_message = "volume_type must be \"MANAGED\" or \"EXTERNAL\"."
  }
}

variable "storage_location" {
  description = "S3 URL for this volume's storage. Required (and only used) when volume_type = \"EXTERNAL\" -- must be a path already covered by an existing external location's credential. Ignored for MANAGED volumes."
  type        = string
  default     = null
}

variable "comment" {
  description = "Optional comment/description for the volume."
  type        = string
  default     = null
}

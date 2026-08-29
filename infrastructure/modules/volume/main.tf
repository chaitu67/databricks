# Provisions one Unity Catalog volume inside an existing catalog/schema
# (5.2-create-unity-catalog creates those). MANAGED volumes need nothing else --
# Databricks stores their files under the owning schema's managed storage
# location automatically. EXTERNAL volumes need storage_location to already be
# covered by a registered external location's storage credential; this module
# does NOT create a new bucket/IAM role/external location per volume the way
# modules/catalog does per catalog -- the root volumes.tf derives
# storage_location from the owning catalog's own external location by default
# (see its comment), so no new AWS/Databricks credential resources are needed
# for the common case of "external volume in the same bucket as its catalog."

resource "databricks_volume" "this" {
  name             = var.name
  catalog_name     = var.catalog_name
  schema_name      = var.schema_name
  volume_type      = var.volume_type
  storage_location = var.volume_type == "EXTERNAL" ? var.storage_location : null
  comment          = var.comment
}

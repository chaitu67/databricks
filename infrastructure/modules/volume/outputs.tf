output "volume_full_name" {
  value = "${var.catalog_name}.${var.schema_name}.${var.name}"
}

output "storage_location" {
  value = databricks_volume.this.storage_location
}

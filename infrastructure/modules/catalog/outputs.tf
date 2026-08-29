output "catalog_name" {
  value = databricks_catalog.this.name
}

output "external_location_url" {
  value = databricks_external_location.this.url
}

output "schema_full_names" {
  value = [for s in databricks_schema.this : "${var.name}.${s.name}"]
}

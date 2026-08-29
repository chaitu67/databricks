# Outputs for downstream skills/consumers go here as resources are added.
# (Comment-only touch to trigger terraform-plan.yml on this PR -- verifies the
# tightened OIDC trust policy's pull_request subject for real before merging.)

output "workspace_urls" {
  description = "Map of workspace slug -> workspace URL, for every entry in var.workspaces."
  value       = { for k, m in module.workspace : k => m.workspace_url }
}

output "workspace_statuses" {
  description = "Map of workspace slug -> workspace_status, for every entry in var.workspaces."
  value       = { for k, m in module.workspace : k => m.workspace_status }
}

output "catalog_names" {
  description = "Map of catalog slug -> catalog name, for every entry in var.catalogs."
  value       = { for k, m in module.catalog : k => m.catalog_name }
}

output "catalog_external_location_urls" {
  description = "Map of catalog slug -> external location S3 URL, for every entry in var.catalogs."
  value       = { for k, m in module.catalog : k => m.external_location_url }
}

output "catalog_schema_full_names" {
  description = "Map of catalog slug -> list of catalog.schema full names, for every entry in var.catalogs."
  value       = { for k, m in module.catalog : k => m.schema_full_names }
}

output "group_names" {
  description = "Map of group slug -> group display name, for every entry in var.groups."
  value       = { for k, m in module.group : k => m.group_name }
}

output "volume_full_names" {
  description = "Map of volume slug -> catalog.schema.volume full name, for every entry in var.volumes."
  value       = { for k, m in module.volume : k => m.volume_full_name }
}

output "volume_storage_locations" {
  description = "Map of volume slug -> resolved storage location (S3 URL for EXTERNAL, Databricks-managed path for MANAGED), for every entry in var.volumes."
  value       = { for k, m in module.volume : k => m.storage_location }
}

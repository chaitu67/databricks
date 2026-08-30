output "workspace_url" {
  description = "URL of this unit's workspace, once RUNNING."
  value       = module.workspace.workspace_url
}

output "workspace_status" {
  value = module.workspace.workspace_status
}

output "catalog_names" {
  description = "Map of LOB catalog key -> catalog name, for every entry in var.catalogs."
  value       = { for k, m in module.catalog : k => m.catalog_name }
}

output "catalog_external_location_urls" {
  description = "Map of LOB catalog key -> external location S3 URL, for every entry in var.catalogs."
  value       = { for k, m in module.catalog : k => m.external_location_url }
}

output "catalog_schema_full_names" {
  description = "Map of LOB catalog key -> list of catalog.schema full names, for every entry in var.catalogs."
  value       = { for k, m in module.catalog : k => m.schema_full_names }
}

output "group_names" {
  description = "Map of LOB catalog key -> { reader, writer, owner } group display names -- what a DIFFERENT unit's own module call reads (module.pattern01_unit_<this_key>.group_names[...]) to build one of its var.extra_grants entries, granting this unit's group access on that other unit's catalog."
  value = {
    for k in keys(var.catalogs) : k => {
      reader = module.reader_group[k].group_name
      writer = module.writer_group[k].group_name
      owner  = module.owner_group[k].group_name
    }
  }
}

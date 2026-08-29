# One Unity Catalog volume per entry in var.volumes (see variables.tf) -- add a
# new volume by adding an entry to the committed volumes.auto.tfvars, never by
# editing this file or any CI workflow. Workspace-scoped (plain default
# databricks provider), same as modules/catalog -- see 5.2-create-unity-catalog's
# SKILL.md "Key difference" for the gotcha this implies about which workspace
# these land in.
#
# EXTERNAL volumes default their storage_location to a subpath under the owning
# catalog's own external location (module.catalog[...].external_location_url)
# when not explicitly set -- avoids provisioning a new bucket/IAM
# role/external location per volume for the common case. An explicit
# storage_location is only needed to point a volume at a genuinely different,
# already-registered external location.
module "volume" {
  source   = "./modules/volume"
  for_each = var.volumes

  catalog_name = module.catalog[each.value.catalog].catalog_name
  schema_name  = each.value.schema
  name         = coalesce(each.value.name, each.key)
  volume_type  = each.value.volume_type
  comment      = each.value.comment
  storage_location = each.value.volume_type != "EXTERNAL" ? null : coalesce(
    each.value.storage_location,
    "${module.catalog[each.value.catalog].external_location_url}/${each.value.schema}/${coalesce(each.value.name, each.key)}"
  )
}

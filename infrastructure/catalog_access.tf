# Unity Catalog privilege grants, one databricks_grants resource per catalog-or-schema
# securable in var.catalog_grants (see variables.tf) -- add a new grant by adding an
# entry to the committed catalog_access.auto.tfvars, never by editing this file or any
# CI workflow. Split into two resources (catalog vs. schema) because databricks_grants
# takes exactly one securable argument -- an entry sets exactly one of them via
# `schema` being null or not. Workspace-scoped (plain default databricks provider),
# same as modules/catalog -- see 5.2-create-unity-catalog's SKILL.md "Key difference"
# for the gotcha this implies about which workspace these land in.
resource "databricks_grants" "catalog" {
  for_each = { for k, v in var.catalog_grants : k => v if v.schema == null }
  catalog  = module.catalog[each.value.catalog].catalog_name

  dynamic "grant" {
    for_each = each.value.grants
    content {
      principal  = module.group[grant.value.group].group_name
      privileges = grant.value.privileges
    }
  }
}

resource "databricks_grants" "schema" {
  for_each = { for k, v in var.catalog_grants : k => v if v.schema != null }
  schema   = "${module.catalog[each.value.catalog].catalog_name}.${each.value.schema}"

  dynamic "grant" {
    for_each = each.value.grants
    content {
      principal  = module.group[grant.value.group].group_name
      privileges = grant.value.privileges
    }
  }
}

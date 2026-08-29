# Provisions one account-level Databricks group and its members. Account-level
# (not workspace-level) because Unity Catalog privilege grants (see the root
# catalog_access.tf, in 5.3-manage-catalog-access) operate on account/metastore-level
# principals -- the same reason modules/workspace looks up databricks_user by email
# for its admin_emails assignment, rather than anything workspace-scoped.

resource "databricks_group" "this" {
  provider     = databricks.mws
  display_name = var.name
}

data "databricks_user" "members" {
  for_each  = toset(var.member_emails)
  provider  = databricks.mws
  user_name = each.value
}

resource "databricks_group_member" "this" {
  for_each  = toset(var.member_emails)
  provider  = databricks.mws
  group_id  = databricks_group.this.id
  member_id = data.databricks_user.members[each.key].id
}

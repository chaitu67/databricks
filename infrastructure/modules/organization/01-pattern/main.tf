# Provisions one "organization unit" -- a dedicated Databricks workspace plus its
# line-of-business catalogs, each with a reader/writer/owner group triad and
# catalog-level grant. This is the reusable building block for "01-pattern" (see
# docs/organization/patterns.md and docs/organization/01-pattern/pattern-definition.md):
# one workspace per business unit/department x environment tier, one catalog per
# line of business inside it. Wraps the same modules/workspace, modules/catalog,
# and modules/group the independent (non-organization) root resources
# (workspaces.tf, catalogs.tf, groups.tf, catalog_access.tf) already use -- this
# module doesn't reimplement any of them, it composes them. A different pattern
# (pattern2, pattern3, ...) gets its own sibling module under
# infrastructure/modules/<pattern>/, scaffolded by
# 6.2.1-build-pattern-module -- this module is 01-pattern's, not "the" module.
#
# This unit's catalog-scoped `databricks` provider is SELF-CONTAINED (see
# providers.tf) -- declared inside this module, not received from the caller via
# a root-level provider alias. Verified empirically (terraform validate + plan)
# that Terraform allows a module to declare its own provider and still be called
# from more than one separately-named module block; the restriction that
# actually exists ("Module is incompatible with count, for_each, and
# depends_on") only bites if the CALLER tries to use count/for_each on the
# module block, which this pattern's scaffolded per-unit blocks never do.
#
# `depends_on` is used for the workspace-scoped resources (rather than an
# implicit data dependency) because this unit's own provider's `host` comes from
# var.workspace.host, a plain input -- not derived from module.workspace's own
# outputs -- so Terraform can't infer "the workspace must exist and be RUNNING
# before this" from the provider wiring alone. Stated explicitly here, same as
# 5.2-create-unity-catalog's SKILL.md already requires by hand for the
# independent path.

module "workspace" {
  source = "../../workspace"

  providers = {
    databricks.mws = databricks.mws
  }

  databricks_account_id     = var.databricks_account_id
  display_name              = var.workspace.display_name
  deployment_name           = coalesce(var.workspace.deployment_name, var.workspace.display_name)
  aws_region                = var.workspace.aws_region
  root_bucket               = var.workspace.root_bucket
  root_bucket_force_destroy = var.workspace.root_bucket_force_destroy
  cross_account_role_name   = coalesce(var.workspace.cross_account_role_name, "databricks-${var.workspace.display_name}-crossaccount")
  pricing_tier              = var.workspace.pricing_tier
  admin_emails              = var.workspace.admin_emails
}

module "catalog" {
  source   = "../../catalog"
  for_each = var.catalogs

  providers = {
    databricks = databricks.this_unit
  }

  databricks_account_id        = var.databricks_account_id
  name                         = each.key
  comment                      = each.value.comment
  bucket_name                  = each.value.bucket_name
  bucket_force_destroy         = each.value.bucket_force_destroy
  storage_credential_role_name = coalesce(each.value.storage_credential_role_name, "databricks-uc-${each.key}-storage")
  schemas                      = each.value.schemas

  depends_on = [module.workspace]
}

module "reader_group" {
  source   = "../../group"
  for_each = var.catalogs

  providers = {
    databricks.mws = databricks.mws
  }

  name          = "acl_${each.key}_reader"
  member_emails = each.value.reader_emails
}

module "writer_group" {
  source   = "../../group"
  for_each = var.catalogs

  providers = {
    databricks.mws = databricks.mws
  }

  name          = "acl_${each.key}_writer"
  member_emails = each.value.writer_emails
}

module "owner_group" {
  source   = "../../group"
  for_each = var.catalogs

  providers = {
    databricks.mws = databricks.mws
  }

  name          = "acl_${each.key}_owner"
  member_emails = each.value.owner_emails
}

locals {
  # Each catalog's own reader/writer/owner triad -- always present, regardless
  # of extra_grants.
  base_grants = {
    for k in keys(var.catalogs) : k => [
      { principal = module.reader_group[k].group_name, privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"] },
      { principal = module.writer_group[k].group_name, privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE", "CREATE_SCHEMA"] },
      { principal = module.owner_group[k].group_name, privileges = ["ALL_PRIVILEGES"] },
    ]
  }

  # var.extra_grants entries scoped to each catalog, keyed the same way --
  # cross-unit grants from a different unit's group (see variables.tf).
  extra_grants_by_catalog = {
    for k in keys(var.catalogs) : k => [
      for g in var.extra_grants : { principal = g.group_name, privileges = g.privileges } if g.catalog_key == k
    ]
  }

  # Merged per catalog -- Databricks only allows one databricks_grants resource
  # per securable, so extra_grants can't be a second, separate resource; they
  # have to land in the same one as the base triad.
  all_grants_by_catalog = {
    for k in keys(var.catalogs) : k => concat(local.base_grants[k], local.extra_grants_by_catalog[k])
  }
}

# One catalog-level grant per catalog, covering the standard reader/writer/owner
# triad (see docs/naming-conventions.md for what each role means) plus any
# cross-unit grants targeting it via var.extra_grants. A grant scoped to a
# single schema (rather than the whole catalog), or a role outside this triad,
# isn't expressible here -- that's the independent path's
# catalog_access.tf/var.catalog_grants, used for anything finer-grained.
resource "databricks_grants" "catalog" {
  for_each = var.catalogs
  catalog  = module.catalog[each.key].catalog_name
  provider = databricks.this_unit

  dynamic "grant" {
    for_each = local.all_grants_by_catalog[each.key]
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }

  depends_on = [module.workspace]
}

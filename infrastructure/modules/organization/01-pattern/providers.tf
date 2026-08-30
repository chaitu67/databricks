# This unit's own catalog-scoped `databricks` provider, self-contained rather
# than received from the root. Terraform allows a module to declare its own
# provider block and still be called from more than one separately-named
# module block (verified empirically: `terraform validate` + `plan` both
# succeeded for exactly this shape) -- the actual restriction
# ("Module is incompatible with count, for_each, and depends_on") only fires if
# the CALLER tries to use `count`/`for_each`/`depends_on` on the module block
# itself, which this pattern's scaffolded per-unit blocks
# (pattern01_units_<unit_key>.tf) never do -- each unit gets its own, distinctly
# named block.
#
# Trade-off accepted for this: since the provider lives inside this module, the
# ROOT has no nameable handle on it -- a cross-unit grant (a different unit's
# group reading one of THIS unit's catalogs) can't be a standalone root
# resource naming `databricks.<this-unit>` the way it could if the provider
# were declared at the root instead. It has to be expressed as an input to
# THIS unit's own module call instead -- see var.extra_grants.
provider "databricks" {
  alias     = "this_unit"
  auth_type = var.auth_type
  profile   = var.auth_type == null ? var.workspace.profile : null
  client_id = var.client_id
  host      = var.workspace.host
}

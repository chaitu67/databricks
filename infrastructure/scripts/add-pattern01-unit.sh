#!/usr/bin/env bash
# Scaffolds Terraform support for one new "01-pattern" organization unit (one
# workspace + its line-of-business catalogs/groups/grants, via
# infrastructure/modules/organization/01-pattern) -- the mechanism behind that
# pattern (see docs/organization/patterns.md and
# docs/organization/01-pattern/pattern-definition.md): one workspace per
# business unit/department x environment tier, one catalog per line of
# business inside it. A different pattern gets its own sibling module/script
# (infrastructure/modules/organization/02-pattern, add-pattern02-unit.sh, ...),
# scaffolded by 6.2.1-build-pattern-module -- this script is "01-pattern"'s
# only. (Terraform identifiers can't start with a digit or contain a hyphen,
# hence "pattern01" in every identifier below rather than the literal
# "01-pattern" folder name.)
#
# Terraform provider configurations can't be generated dynamically via
# for_each/count, so a brand new unit_key needs a real, minimal code addition
# (one module block) -- this script makes that a single, idempotent command
# instead of hand-authored HCL, matching this project's other implement.sh
# scripts. It never edits any *.auto.tfvars and never runs terraform itself.
#
# There is no separate provider file to maintain:
# infrastructure/modules/organization/01-pattern declares its own
# catalog-scoped `databricks` provider internally (see that module's
# providers.tf), parameterized by this unit's own workspace.host/profile —
# verified that Terraform allows this as long as the module is never called
# with count/for_each, which this scaffold's per-unit blocks never do.
#
# Usage: add-pattern01-unit.sh <unit_key>
#
# <unit_key> must match ^[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*$ (lowercase,
# underscore-separated, starts with a letter) and becomes the module name
# `pattern01_unit_<unit_key>` in a new `pattern01_units_<unit_key>.tf`.
#
# After running this script:
#   1. Add this unit_key's entry to pattern01_units.auto.tfvars (workspace
#      config + line-of-business catalogs) -- see
#      infrastructure/modules/organization/01-pattern's variables.tf for the
#      exact shape. Leave workspace.host null and catalogs {} for a brand-new
#      unit's first submission (host is only knowable once the workspace is
#      actually created and RUNNING -- see 6.4-deploy-organization's
#      "two-phase reality"); fill both in on the catalogs follow-up.
#   2. For a cross-unit grant targeting this unit's catalogs, hand-edit this
#      unit's own generated pattern01_units_<unit_key>.tf to add an
#      `extra_grants` entry (see infrastructure/modules/organization/01-pattern's
#      variables.tf) -- the one input on this module meant to be edited by
#      hand over time.
#   3. terraform validate / plan as usual.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

UNIT_KEY="${1:-}"

if [[ -z "$UNIT_KEY" ]]; then
  echo "Usage: $0 <unit_key>" >&2
  exit 1
fi

if ! [[ "$UNIT_KEY" =~ ^[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*$ ]]; then
  echo "Error: unit_key '$UNIT_KEY' must match ^[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*\$ (lowercase, underscore-separated, starts with a letter)." >&2
  exit 1
fi

UNIT_FILE="pattern01_units_${UNIT_KEY}.tf"

if [[ -f "$UNIT_FILE" ]]; then
  echo "Nothing to do -- $UNIT_FILE already exists for unit_key '$UNIT_KEY'."
  exit 0
fi

echo "Scaffolding \"01-pattern\" unit '$UNIT_KEY'..."

cat > "$UNIT_FILE" <<EOF
# Scaffolded by scripts/add-pattern01-unit.sh for unit_key "${UNIT_KEY}".
# Workspace/catalog/role data comes entirely from
# var.pattern01_units["${UNIT_KEY}"] (pattern01_units.auto.tfvars) -- never
# edit this file to change what gets created, except to add/update the
# extra_grants argument below (cross-unit grants targeting this unit's
# catalogs -- see infrastructure/modules/organization/01-pattern's
# variables.tf).
module "pattern01_unit_${UNIT_KEY}" {
  source = "./modules/organization/01-pattern"

  providers = {
    databricks.mws = databricks.mws
  }

  databricks_account_id = var.databricks_account_id
  auth_type              = var.databricks_auth_type
  client_id              = var.databricks_client_id
  workspace               = var.pattern01_units["${UNIT_KEY}"].workspace
  catalogs                = var.pattern01_units["${UNIT_KEY}"].catalogs

  # extra_grants = [
  #   {
  #     catalog_key = "..."
  #     group_name  = module.pattern01_unit_<other_key>.group_names["..."].reader
  #     privileges  = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  #   },
  # ]
}
EOF

echo "Done. Scaffolded ${UNIT_FILE}."
echo ""
echo "Next: add \"${UNIT_KEY}\"'s workspace/catalogs entry to"
echo "pattern01_units.auto.tfvars (host/catalogs left empty for a brand-new"
echo "unit's first submission), then terraform validate / plan as usual --"
echo "this script never runs terraform itself."

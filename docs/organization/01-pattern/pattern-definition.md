# 01-pattern: workspace-per-unit, LOB-as-catalog

See [../patterns.md](../patterns.md) for the pattern registry this belongs to.

## Shape

- One Databricks workspace per business unit / shared department × environment tier it needs.
  Workspace name: `<org>_<bu_or_dept_key>_<env>` (naming-conventions.md `Workspace names`
  section).
- One Unity Catalog catalog per line of business, living inside its owning unit's workspace.
  Catalog name: `<env>_<bu_or_dept_key>_<lob_key>` (naming-conventions.md `domain`/`subdomain`).
  A unit with no LOB split gets one catalog per environment tier (domain only, no subdomain).
- Schemas: `bronze`/`silver`/`gold` per catalog, by default.
- Groups: one reader/writer/owner triad per catalog (`acl_<catalog_key>_<role>`), account-level.
- Grants: catalog-level, one per catalog, granting the triad above the standard privilege sets,
  merged with any cross-unit grants targeting that catalog (see `extra_grants` below) — Databricks
  only allows one grants resource per securable, so these can't be two separate resources.

## Where it's implemented

- **Terraform module**: `infrastructure/modules/organization/01-pattern` — composes
  `modules/workspace` + `modules/catalog` + `modules/group`, doesn't reimplement them. Declares
  its own catalog-scoped `databricks` provider internally (`providers.tf`, aliased `this_unit`,
  parameterized by `var.workspace.host`/`.profile`) rather than receiving one from the root —
  verified empirically that Terraform permits this as long as the module is never called with
  `count`/`for_each` (it isn't; every unit gets its own distinctly-named module block). (Terraform
  identifiers can't start with a digit or contain a hyphen, so this pattern's variable/module names
  use the stem `pattern01` rather than the literal `01-pattern` folder name — see
  `../patterns.md`'s naming-convention note.)
- **Root wiring per unit**: `infrastructure/pattern01_units_<unit_key>.tf` — one module block per
  unit, scaffolded by `infrastructure/scripts/add-pattern01-unit.sh <unit_key>`. No separate
  provider file at the root (unlike an earlier version of this pattern) — the module's
  self-contained provider means there's nothing left for the root to declare beyond the module
  call itself.
- **Unit data**: `infrastructure/pattern01_units.auto.tfvars` (`var.pattern01_units`) — workspace
  config (including `host`/`profile`) and line-of-business catalogs, all in one place.
- **Cross-unit grants**: a `var.extra_grants` entry on the *target* unit's own module call (in its
  `pattern01_units_<unit_key>.tf`, hand-edited — the one input on this module meant to change
  outside of a tfvars edit), referencing the *granting* unit's own
  `module.pattern01_unit_<key>.group_names[...]` output directly. Not a standalone root resource —
  the granting mechanism moved here specifically because the target's provider is no longer
  nameable from the root once it's self-contained inside the module.

## Known limitations

- Terraform provider configurations can't be generated dynamically via `for_each`/`count`, so a
  brand-new `unit_key` needs the one-time `add-pattern01-unit.sh` scaffold before its data becomes
  a pure tfvars edit.
- A brand-new unit's workspace and its catalogs can't land in the same PR/apply — the catalog's
  provider needs the workspace's real, Databricks-assigned URL, which isn't known until the
  workspace is actually `RUNNING`. See `6.4-deploy-organization`'s "two-phase reality" section for
  how that's sequenced across two PRs.
- A cross-unit grant requires hand-editing the target unit's own generated
  `pattern01_units_<unit_key>.tf` (adding an `extra_grants` entry) rather than a fully independent
  file — a direct consequence of the self-contained-provider design, traded deliberately for
  having one fewer root-level file to maintain per unit.
- No volume support, no workspace-login/permission assignment for the groups it creates, no
  row/column masking (`abac` reserved, not built) — same gaps as the independent path's
  `5.3`/`5.4`, not solved by this pattern either.

## Status

Built and validated on 2026-08-30, in two passes: the original design (root-declared provider per
unit) planned cleanly (26 resources, 0 errors), then was redesigned to the self-contained-provider
shape described above after empirically confirming Terraform permits it — re-validated with two
throwaway units (52 resources combined, 0 errors), specifically exercising `extra_grants`: unit
A's `databricks_grants` plan output was confirmed to include unit B's reader group
(`acl_dev_test_unit_b_lob1_reader`) alongside unit A's own reader/writer/owner triad, resolved
directly across module instances. Zero regression on the pre-existing independent-path `analytics`
catalog in both passes. **Not yet applied** to real infrastructure — nothing under this pattern
has been created in real Databricks/AWS.

## Org instances using this pattern

Each org modeled against this pattern gets its own subfolder here
(`docs/organization/01-pattern/<org-slug>/`), holding that org's own
`org-structure.yaml`/`databricks-mapping.md`/`deployment-plan.md`:

- [meridian-financial/](meridian-financial/org-structure.yaml) — a genericized test org modeled
  through `6.1`–`6.3`, planning-only, nothing deployed.
- [northwind-financial/](northwind-financial/org-structure.yaml) — a second genericized org,
  currently at `6.1` (structure discovered; mapping/plan not yet generated).
- [skyway-air/](skyway-air/org-structure.yaml) — a third genericized org (shape inspired by a
  public airline reference, not modeling a real company), currently at `6.1` (structure discovered;
  mapping/plan not yet generated).

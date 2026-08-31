# Naming conventions: catalogs and groups

These conventions exist so that, at enterprise scale, anyone can predict a catalog or group name
from its business meaning alone -- no lookup table, no tribal knowledge. They are enforced by a
Terraform `validation` block on the relevant variable in `infrastructure/variables.tf`, **only
for `environment = "prod"` entries** -- `dev`/`stg` entries are never validated, so local
experimentation is never blocked by this. This is real, automatic enforcement: it fires on
`terraform plan`/`apply` for anyone editing the committed tfvars directly, not only when going
through a `05-databricks-terraform-deployment` skill conversation.

## Environment tiers

Every catalog and every group declares `environment = "dev" | "stg" | "prod"` (defaults to
`"dev"` if omitted). Only `"prod"` is pattern-enforced.

## Catalog names

```
<env>_<domain>[_<subdomain>]
```

- `env` -- `dev` | `stg` | `prod`, must match the entry's own `environment` field.
- `domain` -- the business domain/team that owns this data (lowercase, starts with a letter):
  `sales`, `marketing`, `finance`, `analytics`, `risk`.
- `subdomain` (optional, repeatable) -- further scoping when one domain needs more than one
  catalog: `analytics_events`, `analytics_ml`.

Regex (prod only): `^(dev|stg|prod)_[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*$`

Examples: `prod_analytics`, `prod_sales_events`, `dev_whatever_you_want` (dev, not enforced).

**Why underscores, not hyphens:** Unity Catalog names are SQL identifiers. A hyphen forces every
query to backtick-quote the catalog (`` `prod-analytics`.bronze.foo ``); underscore never does.
This is a real technical constraint, not a style preference -- even though this project's
AWS-facing names (S3 buckets, IAM roles) use hyphens elsewhere, which is fine since those aren't
SQL identifiers.

## Group names

```
<type>_<env>_<domain>[_<subdomain>]_<role>
```

- `type` -- what kind of access-control construct this group is for. An **extensible enum**,
  designed up front for where this is headed, not just what exists today:
  - `acl` -- **implemented today** (via `5.3-manage-catalog-access`). A group of human users,
    granted object-level privileges (`databricks_grants`) on a catalog or schema.
  - `sp` -- **reserved, not yet implemented.** Same role vocabulary and grant mechanism as `acl`,
    but membership is service principals (jobs/pipelines/apps), not human users. Needs its own
    module (a `databricks_service_principal` lookup instead of `5.3`'s `databricks_user` lookup)
    -- don't force service-principal membership through `5.3`'s current `modules/group` as a
    workaround; build the distinct module when this is actually needed.
  - `abac` -- **reserved, not yet implemented anywhere in this project.** Databricks
    attribute-based access control (tag-driven policies, e.g. row/column masking) is a distinct
    mechanism from object-level ACL grants and has no Terraform resources here yet. The `<role>`
    segment's vocabulary for `abac` groups is deliberately left undefined until that capability
    is actually built -- don't invent a placeholder convention for it now.
  - New types can be added later the same way: extend the enum, extend the validation regex,
    build the matching module. The naming scheme is meant to absorb that without a rename wave.
- `env` -- `dev` | `stg` | `prod`, must match the entry's own `environment` field, and should
  match the `env` of every catalog this group is ever granted against (a `prod` group should
  never hold a grant on a `dev` catalog, or vice versa).
- `domain` / `subdomain` -- mirrors the catalog naming above, so a group's scope is legible
  against the catalog(s) it will be granted on: `grp` for `acl` isn't used here on purpose --
  `type` already carries that signal, see below.
- `role` -- `reader` | `writer` | `owner` (applies to `acl` and `sp`; undefined for `abac` until
  built):
  - `reader` = `USE_CATALOG`/`USE_SCHEMA` + `SELECT`
  - `writer` = `reader` + `MODIFY` + `CREATE_TABLE` (+ `CREATE_SCHEMA` at catalog level)
  - `owner` = `ALL_PRIVILEGES`

Regex (prod only, `acl`/`sp` types): `^(acl|sp)_(dev|stg|prod)_[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*_(reader|writer|owner)$`

Examples: `acl_prod_analytics_reader`, `acl_prod_sales_events_writer`, `sp_prod_analytics_writer`
(mechanism not yet built), `acl_dev_whatever_owner` (dev, not enforced).

## Workspace names (01-pattern / BU path)

```
<org>_<bu_or_dept_key>_<env>
```

- Applies to workspaces created through the `06-organization-setup` 01-pattern (one workspace per
  business unit/department x environment tier) -- `pattern01_units.auto.tfvars`'s `display_name`
  and `deployment_name`. Standalone workspaces created outside that pattern (e.g.
  `workshop-workspace`) aren't org/BU-scoped and don't follow this.
- `org` -- the org's slug from its `docs/organization/01-pattern/<org-slug>/org-structure.yaml`
  (e.g. `harbor_health` for the `harbor-health` org).
- `bu_or_dept_key` -- the unit's `key` from that same `org-structure.yaml`.
- `env` -- the environment tier this workspace serves (`dev` | `stg` | `prod`).

Example: org `harbor-health`, unit `pharmacy`, tier `dev` -> `harbor_health_pharmacy_dev`.

**Why underscores here despite the hyphen-elsewhere rule above:** a workspace's `display_name` is
a human-readable label, not a SQL identifier or a DNS-facing value (the actual workspace URL is
Databricks-auto-assigned, independent of this name -- see `modules/workspace/main.tf`), so the SQL
constraint that forces underscores on catalogs doesn't apply here. This convention is a deliberate
choice for consistency with the rest of this project's account-level naming, not a technical
requirement -- unlike the catalog rule above.

**Renaming a live workspace's `display_name`/`deployment_name` (`workspace_name` on
`databricks_mws_workspaces`) forces Terraform to destroy and recreate the whole workspace** --
`workspace_name` is a ForceNew field in this provider, even though the Databricks account API
itself supports an in-place rename (`databricks account workspaces update <id>
--workspace-name ...`). Applying this convention to an already-`RUNNING` workspace is a real,
data-losing replace; get explicit sign-off before merging a PR that renames one, and prefer the
out-of-band CLI rename + state-refresh reconciliation route over a Terraform-driven
destroy/recreate wherever the workspace already has anything in it worth keeping.

## Volume names

```
<purpose>[_<subtype>]
```

- No `env`/`domain` prefix, unlike catalogs/groups -- a volume already lives inside a specific
  `catalog.schema` (via `5.4-create-volume`), which already carries that context. Repeating it in
  the volume name itself would be redundant, not informative.
- `purpose` -- what the volume is for (lowercase, starts with a letter): `raw_files`,
  `model_artifacts`, `landing_zone`.
- `subtype` (optional, repeatable) -- further scoping: `raw_files_partner_a`.

Regex (enforced unconditionally -- no dev/stg/prod carve-out, since volumes have no `environment`
field of their own): `^[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*$`

Examples: `raw_files`, `model_artifacts`, `analytics_export_v2`.

**Same underscore rule as catalogs**: Unity Catalog volume names are SQL identifiers too, so
hyphens would force backtick-quoting every reference.

This applies to the *effective* name -- the `name` field in a `volumes.auto.tfvars` entry, or the
map key itself when `name` is omitted (see `5.4-create-volume`'s `SKILL.md`).

## What this project actually enforces today

`catalogs` (via `5.2-create-unity-catalog`), `groups` with `type = acl` (via
`5.3-manage-catalog-access`), and `volumes` (via `5.4-create-volume`) all have real Terraform
`validation` blocks. `sp` and `abac` are reserved vocabulary for when those capabilities get
built -- referencing them here now avoids a naming-scheme rewrite later, without pretending either
capability exists yet.

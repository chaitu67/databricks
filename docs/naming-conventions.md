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

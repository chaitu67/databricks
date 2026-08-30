# Organization patterns

A "pattern" is a named, reusable Databricks-mapping *strategy* for turning an org model
(`org-structure.yaml`, from `6.1-discover-org-structure`) into real Databricks/Terraform
primitives — which workspace(s), which catalogs, which groups/grants. Multiple orgs can share the
same pattern; a genuinely different org shape (different workspace strategy, different
catalog/schema layout, different isolation requirements) gets its own new pattern instead of
bending an existing one to fit.

| Pattern | Strategy | Terraform module | Scaffold script | Status |
|---|---|---|---|---|
| [01-pattern](01-pattern/pattern-definition.md) | One workspace per business unit/department × environment tier; a line of business (LOB) is a catalog inside its unit's workspace. Catalog-scoped provider is self-contained inside the module (see pattern-definition.md). | `infrastructure/modules/organization/01-pattern` | `infrastructure/scripts/add-pattern01-unit.sh` | Built + validated (two throwaway units, 52 resources combined, 0 errors — including a cross-unit `extra_grants` reference); not applied to real infrastructure. |

## Naming convention: folder name vs. Terraform identifier stem

A pattern's **folder name** (both `docs/organization/<N>-pattern/` and
`infrastructure/modules/organization/<N>-pattern/`) is a zero-padded, hyphenated ordinal:
`01-pattern`, `02-pattern`, `03-pattern`, ... A pattern's **Terraform identifier stem** (variable
names, module block names, scaffold script filename) is the same ordinal without the hyphen —
`pattern01`, `pattern02`, ... — because Terraform identifiers can't start with a digit or contain
a hyphen. Both always refer to the same pattern; only the spelling differs by context. `01-pattern`
(folder) / `pattern01` (identifiers) is the first one.

## Adding a new pattern

When `6.2-map-databricks-pattern` determines an org's needs don't fit any pattern listed above,
invoke **`6.2.1-build-pattern-module`** to define and scaffold the next one (`02-pattern`,
`03-pattern`, ...) — never bend an existing pattern's module to fit a shape it wasn't designed for,
and never hand-write a new pattern's Terraform without going through that skill. It keeps every
pattern's module, scaffold script, root wiring, and docs consistent with the conventions
established here:

- `docs/organization/<N>-pattern/pattern-definition.md` — the strategy itself: workspace/catalog/
  schema/group/grant shape, what Terraform realizes it, what it does and doesn't support.
- `infrastructure/modules/organization/<N>-pattern/` — the reusable Terraform module(s), composed
  from the existing primitives (`modules/workspace`, `modules/catalog`, `modules/group`,
  `modules/volume`) wherever they fit, same as `01-pattern` does. If the pattern needs dedicated
  per-unit workspaces, prefer `01-pattern`'s self-contained-provider design (the module declares
  its own catalog-scoped `databricks` provider, parameterized by a `host`/`profile` input —
  verified this is legal as long as the module is never called with `count`/`for_each`) over a
  separate root-level provider file — one fewer file to maintain per unit. The trade-off:
  cross-unit grants then have to be an input on the *target* unit's own module call (see
  `01-pattern`'s `extra_grants`) rather than a standalone root resource, since the root has no
  nameable handle on a self-contained provider. If a future pattern's cross-unit-grant ergonomics
  matter more than that one file, a root-declared provider (naming it from a standalone root
  resource) is the alternative — just a deliberate choice either way, not a Terraform requirement
  in either direction.
- `infrastructure/pattern<NN>_units_<unit_key>.tf`, `infrastructure/scripts/add-pattern<NN>-unit.sh`
  — the per-unit module-call scaffolding, if the new pattern needs dedicated per-unit workspaces at
  all (not every pattern necessarily will).
- A new row in the table above.

## Per-org instance docs

Each pattern's own subfolder (`docs/organization/<N>-pattern/`) also holds one subfolder per org
modeled against it — `docs/organization/<N>-pattern/<org-slug>/` — containing that org's own
`org-structure.yaml`, `databricks-mapping.md`, `deployment-plan.md`. Multiple orgs can share one
pattern; each gets its own org-slug subfolder, never sharing a flat set of files with another org.
`01-pattern/` currently holds three such instances, all genericized: `meridian-financial/`
(planning-only, `6.1`–`6.3` complete), `northwind-financial/` (in progress, `6.1` complete), and
`skyway-air/` (in progress, `6.1` complete).

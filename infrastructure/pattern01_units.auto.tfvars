# "01-pattern" organization units -- one Databricks workspace per business
# unit/department x environment tier, per docs/organization/01-pattern/pattern-definition.md.
# Add a new unit_key by running scripts/add-pattern01-unit.sh <unit_key> first (scaffolds its
# module block), then adding its entry here. A brand-new unit's first submission leaves
# workspace.host null and catalogs {} -- host is only knowable once the workspace is actually
# created and RUNNING (see 6.4-deploy-organization's "two-phase reality"); catalogs follow in a
# second PR once that's confirmed.
pattern01_units = {}

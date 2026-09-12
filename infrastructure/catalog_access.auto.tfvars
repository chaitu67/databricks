# Unity Catalog privilege grants -- one map entry per catalog-or-schema securable. Add a
# new grant by adding an entry here (or a new `grants` list item to an existing entry),
# open a PR, merge. Terraform auto-loads this file locally and in CI: no TF_VAR_, no
# `gh variable set`, no workflow YAML edit needed for a new grant.
#
# Catalog-level (schema = null): USE_CATALOG/USE_SCHEMA + SELECT (reader), + MODIFY +
# CREATE_TABLE + CREATE_SCHEMA (writer), or ALL_PRIVILEGES (owner) -- applies to the whole
# analytics catalog, cascading to every current and future schema/table within it.
catalog_grants = {}

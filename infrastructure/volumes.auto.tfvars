# Unity Catalog volumes to create -- one map entry each. Add a new volume by adding
# an entry here (catalog/schema/name/type -- none of this is secret), open a PR,
# merge. Terraform auto-loads this file locally and in CI: no TF_VAR_, no
# `gh variable set`, no workflow YAML edit needed for a new volume.
#
# EXTERNAL entries with storage_location left unset default (in volumes.tf) to a
# subpath under their own catalog's already-registered external location -- no new
# bucket/IAM role/external location per volume.
volumes = {
  "analytics-bronze-raw-files" = {
    catalog     = "analytics"
    schema      = "bronze"
    name        = "raw_files"
    volume_type = "EXTERNAL"
    comment     = "External landing volume for raw files dropped into the bronze schema"
  }
}

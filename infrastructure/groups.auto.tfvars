# Account-level Databricks groups to create -- one map entry each. Add a new group by
# adding an entry here (name/members -- none of this is secret), open a PR, merge.
# Terraform auto-loads this file locally and in CI: no TF_VAR_, no `gh variable set`,
# no workflow YAML edit needed for a new group.
#
# environment = "prod" entries have their key pattern-enforced
# (acl_<env>_<domain>[_<subdomain>]_<role>) -- see docs/naming-conventions.md. These are
# all "dev" (matching the analytics catalog's own environment = "dev"), so the naming
# pattern isn't enforced here -- the acl_dev_analytics_<role> names are still used
# voluntarily, for consistency with the convention.
groups = {
  "acl_dev_analytics_reader" = {
    environment   = "dev"
    member_emails = ["datagaiinc@gmail.com"]
  }
  "acl_dev_analytics_writer" = {
    environment   = "dev"
    member_emails = ["datagaiinc@gmail.com"]
  }
  "acl_dev_analytics_owner" = {
    environment   = "dev"
    member_emails = ["datagaiinc@gmail.com"]
  }
}

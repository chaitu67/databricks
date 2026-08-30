variable "databricks_account_id" {
  description = "Databricks account ID -- reused as the workspace's cross-account role external_id and the catalogs' storage credential external_id, same idiom as modules/workspace and modules/catalog."
  type        = string
}

variable "auth_type" {
  description = "Same meaning as the root's var.databricks_auth_type -- passed straight through so this unit's own self-contained catalog-scoped provider (see providers.tf) authenticates the same way as the rest of this project: profile-based OAuth locally, github-oidc in CI. Not unit-specific; every unit is called with the same root-level value."
  type        = string
  default     = null
}

variable "client_id" {
  description = "Same meaning as the root's var.databricks_client_id -- passed straight through for the same reason as auth_type."
  type        = string
  default     = null
}

variable "workspace" {
  description = "This unit's dedicated Databricks workspace -- one per business unit/department x environment tier, per the 06-organization-setup skill group's canonical pattern (see docs/organization/). display_name/aws_region/root_bucket/etc. match modules/workspace's own variables (deployment_name/cross_account_role_name default the same way the root workspaces.tf already does for the independent path). host/profile are this unit's OWN workspace's connection details, used only by this module's self-contained catalog-scoped provider (providers.tf) -- host is only knowable once the workspace is actually created and RUNNING, so leave it null for a brand-new unit's first submission (when catalogs is also {}) and fill it in on the catalogs follow-up -- see 6.4-deploy-organization's 'two-phase reality' section."
  type = object({
    display_name              = string
    deployment_name           = optional(string)
    aws_region                = string
    root_bucket               = string
    root_bucket_force_destroy = optional(bool, false)
    cross_account_role_name   = optional(string)
    pricing_tier              = optional(string, "PREMIUM")
    admin_emails              = optional(list(string), [])
    host                      = optional(string)
    profile                   = optional(string)
  })
}

variable "catalogs" {
  description = "This unit's line-of-business catalogs, keyed by the catalog's real full name (same <env>_<domain>[_<subdomain>] convention as the independent path's var.catalogs -- see docs/naming-conventions.md; domain is normally this unit's own key, subdomain the LOB's key). One catalog, plus a reader/writer/owner group triad and catalog-level grant, is created per entry automatically -- see main.tf. Leave reader/writer/owner_emails empty to create a group with no members yet (addable later without touching this module)."
  type = map(object({
    environment                  = optional(string, "dev")
    comment                      = optional(string)
    bucket_name                  = string
    bucket_force_destroy         = optional(bool, false)
    storage_credential_role_name = optional(string)
    schemas                      = optional(list(string), [])
    reader_emails                = optional(list(string), [])
    writer_emails                = optional(list(string), [])
    owner_emails                 = optional(list(string), [])
  }))
  default = {}
}

variable "extra_grants" {
  description = "Cross-unit grants targeting THIS unit's own catalogs -- how a different unit's group (e.g. a shared department's reader group) gets access here, since this unit's catalog-scoped provider is self-contained and no longer nameable from the root (see providers.tf). Each entry's catalog_key must be a key in var.catalogs above; group_name is the fully-resolved group display name, normally read from another unit's own module output (module.pattern01_unit_<other_key>.group_names[\"<catalog_key>\"].reader, for example). Merged into the SAME databricks_grants resource as this catalog's own reader/writer/owner triad (Databricks only allows one such resource per securable) -- see main.tf. This is the one input on this module meant to be hand-edited over time as new cross-unit grants are needed, unlike every other argument (which only ever changes via this unit's own pattern01_units.auto.tfvars entry)."
  type = list(object({
    catalog_key = string
    group_name  = string
    privileges  = list(string)
  }))
  default = []
}

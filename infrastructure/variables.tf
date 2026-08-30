variable "aws_region" {
  description = "AWS region to deploy Databricks-related infrastructure into."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to authenticate with. Leave null to use the default credential chain."
  type        = string
  default     = null
}

variable "databricks_profile" {
  description = "~/.databrickscfg profile for the default (non-account) Databricks provider. Populated by `databricks auth login` (OAuth) via the 3.2.2-authenticate-databricks skill — the 'DEFAULT' profile is used unless a workspace host/token override below is set."
  type        = string
  default     = "DEFAULT"
}

variable "databricks_host" {
  description = "Databricks workspace URL, e.g. https://<workspace>.cloud.databricks.com. Only needed to override the profile above with explicit host+token (PAT) auth; leave null to use databricks_profile."
  type        = string
  default     = null
}

variable "databricks_token" {
  description = "Databricks personal access token, only used if databricks_host is also set. Pass via TF_VAR_databricks_token or a gitignored .tfvars file — never commit it. Leave null to use databricks_profile (OAuth) instead."
  type        = string
  sensitive   = true
  default     = null
}

variable "databricks_auth_type" {
  description = "Explicit Databricks provider auth type override. Set to \"github-oidc\" for GitHub Actions workload identity federation (paired with databricks_client_id below; no stored secret) — set via TF_VAR_databricks_auth_type in the GitHub Actions workflow, per the 04-github-cicd skill group. Leave null for local use, which falls back to databricks_profile (or databricks_host/databricks_token) exactly as before this variable existed."
  type        = string
  default     = null
}

variable "databricks_client_id" {
  description = "Application ID (client ID -- not a secret) of the Databricks service principal used for GitHub Actions workload identity federation. Only read when databricks_auth_type = \"github-oidc\"; set via TF_VAR_databricks_client_id (a plain GitHub Actions repo variable, since it grants no access by itself)."
  type        = string
  default     = null
}

variable "workspaces" {
  description = "Map of Databricks workspaces to create, keyed by a short slug (used to default deployment_name/cross_account_role_name and as the module instance key). Values come from the committed workspaces.auto.tfvars -- add an entry there to provision a new workspace; no CI/workflow changes needed."
  type = map(object({
    display_name              = string
    deployment_name           = optional(string)
    aws_region                = optional(string)
    root_bucket               = string
    root_bucket_force_destroy = optional(bool, false)
    cross_account_role_name   = optional(string)
    pricing_tier              = optional(string, "PREMIUM")
    admin_emails              = optional(list(string), [])
  }))
  default = {}
}

variable "catalogs" {
  description = "Map of Unity Catalog catalogs to create, keyed by a short slug (the catalog name and the module instance key). Values come from the committed catalogs.auto.tfvars -- add an entry there to provision a new catalog; no CI/workflow changes needed. Each catalog gets its own dedicated S3 bucket + IAM role + storage credential + external location. See docs/naming-conventions.md: for environment = \"prod\" entries, the map key must match <env>_<domain>[_<subdomain>] (e.g. prod_analytics) -- dev/stg keys are unrestricted."
  type = map(object({
    environment                  = optional(string, "dev")
    comment                      = optional(string)
    bucket_name                  = string
    bucket_force_destroy         = optional(bool, false)
    storage_credential_role_name = optional(string)
    schemas                      = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.catalogs : contains(["dev", "stg", "prod"], v.environment)
    ])
    error_message = "Each catalog's environment must be \"dev\", \"stg\", or \"prod\"."
  }

  validation {
    # Naming pattern only enforced for prod -- see docs/naming-conventions.md.
    condition = alltrue([
      for k, v in var.catalogs : (
        v.environment != "prod" ||
        can(regex("^(dev|stg|prod)_[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*$", k))
      )
    ])
    error_message = "Catalog keys with environment = \"prod\" must match <env>_<domain>[_<subdomain>] (e.g. prod_analytics) -- see docs/naming-conventions.md."
  }
}

variable "pattern01_units" {
  description = "Map of \"01-pattern\" organization units, keyed by unit_key -- one Databricks workspace per business unit/department x environment tier, per that pattern (see docs/organization/patterns.md and docs/organization/01-pattern/pattern-definition.md). Values come from the committed pattern01_units.auto.tfvars. Editing an EXISTING unit's data (adding a line-of-business catalog, changing a bucket name, updating role membership, or setting workspace.host once RUNNING) is a pure tfvars edit -- no code change. A BRAND NEW unit_key additionally needs a one-time scaffold (infrastructure/scripts/add-pattern01-unit.sh <unit_key>) that wires its module block (pattern01_units_<unit_key>.tf) -- Terraform provider configurations can't be generated dynamically via for_each/count, so that one step is a real, minimal code addition, not a tfvars-only one, unlike every other resource in this project (this unit's own catalog-scoped provider is self-contained inside infrastructure/modules/organization/01-pattern itself, not a separate root-level provider file -- see that module's providers.tf). See infrastructure/modules/organization/01-pattern for the full schema, including var.extra_grants for cross-unit access. A different pattern gets its own sibling variable (pattern02_units, ...) and its own infrastructure/modules/organization/02-pattern/ folder, scaffolded by 6.2.1-build-pattern-module -- this variable is \"01-pattern\"'s, not shared. (Terraform identifiers can't start with a digit or contain a hyphen, hence \"pattern01\" here rather than the literal \"01-pattern\" folder name.)"
  type = map(object({
    workspace = object({
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
    catalogs = optional(map(object({
      environment                  = optional(string, "dev")
      comment                      = optional(string)
      bucket_name                  = string
      bucket_force_destroy         = optional(bool, false)
      storage_credential_role_name = optional(string)
      schemas                      = optional(list(string), [])
      reader_emails                = optional(list(string), [])
      writer_emails                = optional(list(string), [])
      owner_emails                 = optional(list(string), [])
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for uk, u in var.pattern01_units : [
        for ck, c in u.catalogs : contains(["dev", "stg", "prod"], c.environment)
      ]
    ]))
    error_message = "Each \"01-pattern\" unit catalog's environment must be \"dev\", \"stg\", or \"prod\"."
  }

  validation {
    # Naming pattern only enforced for prod, same carve-out as the independent
    # path's var.catalogs -- see docs/naming-conventions.md.
    condition = alltrue(flatten([
      for uk, u in var.pattern01_units : [
        for ck, c in u.catalogs : (
          c.environment != "prod" ||
          can(regex("^(dev|stg|prod)_[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*$", ck))
        )
      ]
    ]))
    error_message = "\"01-pattern\" unit catalog keys with environment = \"prod\" must match <env>_<domain>[_<subdomain>] (e.g. prod_retail_brokerage) -- see docs/naming-conventions.md."
  }
}

variable "groups" {
  description = "Map of account-level Databricks groups to create, keyed by a short slug (used as the group's display name and module instance key). Values come from the committed groups.auto.tfvars -- add an entry there to provision a new group; no CI/workflow changes needed. Groups are account-level (shared across every workspace attached to this account), matching how Unity Catalog grants work. See docs/naming-conventions.md: for environment = \"prod\" entries, the map key must match acl_<env>_<domain>[_<subdomain>]_<role> (e.g. acl_prod_analytics_reader) -- dev/stg keys are unrestricted. Only the \"acl\" group type (object-level catalog/schema grants, what this skill builds) is validated today; \"sp\"/\"abac\" are reserved vocabulary for capabilities not yet implemented."
  type = map(object({
    environment   = optional(string, "dev")
    member_emails = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.groups : contains(["dev", "stg", "prod"], v.environment)
    ])
    error_message = "Each group's environment must be \"dev\", \"stg\", or \"prod\"."
  }

  validation {
    # Naming pattern only enforced for prod, and only for the "acl" group type -- "sp"/"abac"
    # are reserved vocabulary for capabilities this project doesn't implement yet. See
    # docs/naming-conventions.md.
    condition = alltrue([
      for k, v in var.groups : (
        v.environment != "prod" ||
        can(regex("^(acl|sp)_(dev|stg|prod)_[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*_(reader|writer|owner)$", k))
      )
    ])
    error_message = "Group keys with environment = \"prod\" must match acl_<env>_<domain>[_<subdomain>]_<role> (e.g. acl_prod_analytics_reader) -- see docs/naming-conventions.md."
  }
}

variable "catalog_grants" {
  description = "Map of Unity Catalog privilege grants, keyed by an arbitrary slug. Each entry grants one or more groups' privileges on either a whole catalog (schema left null) or one schema within it (schema set). Values come from the committed catalog_access.auto.tfvars -- add an entry there to grant access; no CI/workflow changes needed. `catalog` must reference an existing key in var.catalogs (5.2-create-unity-catalog); `group` in each grants[] entry must reference an existing key in var.groups."
  type = map(object({
    catalog = string
    schema  = optional(string)
    grants = list(object({
      group      = string
      privileges = list(string)
    }))
  }))
  default = {}
}

variable "volumes" {
  description = "Map of Unity Catalog volumes to create, keyed by an arbitrary slug. Values come from the committed volumes.auto.tfvars -- add an entry there to provision a new volume; no CI/workflow changes needed. `catalog` must reference an existing key in var.catalogs (5.2-create-unity-catalog); `schema` must already exist in that catalog's schemas list. `name` defaults to the map key when omitted -- set it explicitly only if the real Unity Catalog volume name should differ from the slug. `volume_type` is \"MANAGED\" (default -- no separate storage needed) or \"EXTERNAL\" (storage_location defaults to a subpath under the owning catalog's own external location when not set explicitly). See docs/naming-conventions.md: the effective name (`name`, or the map key when `name` is omitted) must match `<purpose>[_<subtype>]` -- lowercase, starting with a letter, underscore-separated -- enforced for every volume regardless of environment, since (unlike catalogs/groups) volumes have no separate environment field of their own; the owning catalog.schema already carries that context."
  type = map(object({
    catalog          = string
    schema           = string
    name             = optional(string)
    volume_type      = optional(string, "MANAGED")
    storage_location = optional(string)
    comment          = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.volumes : contains(["MANAGED", "EXTERNAL"], v.volume_type)
    ])
    error_message = "Each volume's volume_type must be \"MANAGED\" or \"EXTERNAL\"."
  }

  validation {
    # Unlike catalogs/groups, this is enforced unconditionally -- volumes have no environment
    # field of their own (the owning catalog.schema already carries env/domain context), so
    # there's no "dev is unrestricted" carve-out here. See docs/naming-conventions.md.
    condition = alltrue([
      for k, v in var.volumes : can(regex("^[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*$", coalesce(v.name, k)))
    ])
    error_message = "Each volume's effective name (`name`, or the map key when `name` is omitted) must match <purpose>[_<subtype>] -- lowercase, starting with a letter, underscore-separated (e.g. raw_files, model_artifacts) -- see docs/naming-conventions.md."
  }
}

# databricks

Terraform-managed Databricks-on-AWS infrastructure: workspaces, Unity Catalog catalogs/schemas,
account-level groups and grants, and volumes. Every change lands here as a PR, planned and applied
by GitHub Actions — nothing is applied by hand.

This repo is driven by the [accelerator](https://github.com/chaitu67/accelerator) repo's Claude
Code skills, cloned as a sibling directory. See that repo's README for the full skill list and a
step-by-step new-user walkthrough; this README covers what actually lives here.

## Layout

```
infrastructure/           Terraform root
  *.auto.tfvars            Committed config — the only thing you usually edit
  modules/workspace/        One Databricks-on-AWS workspace (VPC/S3/IAM + MWS resources)
  modules/catalog/          One Unity Catalog catalog + schemas
  modules/group/             One account-level group + membership
  modules/volume/            One Unity Catalog volume
  modules/organization/01-pattern/  One workspace-per-BU × env, LOB-as-catalog (see docs/organization)
  scripts/                   One-time scaffolding (e.g. add-pattern01-unit.sh)
.github/workflows/         terraform-plan.yml / terraform-apply.yml (PR-triggered CI/CD), security-scan.yml (Checkov on every PR)
docs/
  naming-conventions.md     Enforced naming rules for catalogs, groups, volumes, and BU-path workspaces
  organization/01-pattern/  Per-org structure/mapping/deployment-plan docs (one subfolder per org modeled)
```

## How changes get applied

1. Edit a committed `*.auto.tfvars` file (or, for a brand-new workspace/catalog/unit, run the
   relevant `accelerator` skill, which scaffolds the one-time module file too).
2. Open a PR. `terraform-plan.yml` runs automatically and posts the plan.
3. A human reviews the plan — this is the only gate; there's no environment where this repo
   applies without one.
4. Merge. `terraform-apply.yml` runs the apply.

No `TF_VAR_`, no `gh variable set`, no workflow YAML edits for routine changes — new workspaces,
catalogs, groups, and volumes are always just a tfvars entry.

## What's deployed

Source of truth is Terraform state (S3 backend, see `infrastructure/backend.tf`), not this file —
treat the below as a snapshot, not a live inventory:

- **Workspaces**: `workshop-workspace` (standalone), plus `pharmacy-dev` — the `pharmacy_dev` unit
  under the `06-organization-setup` 01-pattern for the `harbor-health` org (see
  `docs/organization/01-pattern/harbor-health/`). A rename to `harbor_health_pharmacy_dev`, per the
  workspace naming convention below, is pending in an open PR as of this writing.
- **Catalogs**: `analytics` (dev), with `acl_dev_analytics_reader/writer/owner` groups granted on
  it.
- **Naming**: enforced for `prod`-tier catalogs/groups/volumes and for all 01-pattern workspaces —
  see [docs/naming-conventions.md](docs/naming-conventions.md).

## Security

- `security-scan.yml` runs Checkov on every PR (secrets, IaC misconfiguration), gated on a curated
  critical-check list.
- This repo is public; see `accelerator`'s `0.2-security-audit` skill for the latest scored audit
  of this repo's GitHub/IaC posture.

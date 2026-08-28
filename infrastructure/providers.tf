provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "databricks" {
  # profile-based OAuth (local use, unchanged default) vs. github-oidc workload identity
  # federation (GitHub Actions CI, set via TF_VAR_databricks_auth_type -- see
  # 04-github-cicd/4.3-configure-github-oidc). profile is left null under github-oidc so it
  # doesn't try to load a local ~/.databrickscfg profile that doesn't exist on a CI runner.
  auth_type = var.databricks_auth_type
  profile   = var.databricks_auth_type == null ? var.databricks_profile : null
  client_id = var.databricks_client_id
  host      = var.databricks_host
  token     = var.databricks_token
}

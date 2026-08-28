# State-address migration for the 2026-08-28 modularization of workspace-creation
# resources out of root workspace.tf into modules/workspace, for_each-keyed by
# workspaces.auto.tfvars entries. These blocks let Terraform re-address the
# already-applied "workshop-workspace" resources in place instead of destroying
# and recreating them. Safe to remove once confirmed applied; harmless to leave.

moved {
  from = aws_iam_role.cross_account
  to   = module.workspace["workshop-workspace"].aws_iam_role.cross_account
}

moved {
  from = aws_iam_role_policy.cross_account
  to   = module.workspace["workshop-workspace"].aws_iam_role_policy.cross_account
}

moved {
  from = time_sleep.iam_propagation
  to   = module.workspace["workshop-workspace"].time_sleep.iam_propagation
}

moved {
  from = aws_s3_bucket.root_storage
  to   = module.workspace["workshop-workspace"].aws_s3_bucket.root_storage
}

moved {
  from = aws_s3_bucket_public_access_block.root_storage
  to   = module.workspace["workshop-workspace"].aws_s3_bucket_public_access_block.root_storage
}

moved {
  from = aws_s3_bucket_policy.root_storage
  to   = module.workspace["workshop-workspace"].aws_s3_bucket_policy.root_storage
}

moved {
  from = databricks_mws_credentials.this
  to   = module.workspace["workshop-workspace"].databricks_mws_credentials.this
}

moved {
  from = databricks_mws_storage_configurations.this
  to   = module.workspace["workshop-workspace"].databricks_mws_storage_configurations.this
}

moved {
  from = databricks_mws_workspaces.this
  to   = module.workspace["workshop-workspace"].databricks_mws_workspaces.this
}

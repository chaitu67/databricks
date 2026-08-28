output "workspace_url" {
  description = "URL of the workspace, once databricks_mws_workspaces reports RUNNING. Auto-assigned by Databricks (deployment_name is intentionally not set -- see main.tf)."
  value       = databricks_mws_workspaces.this.workspace_url
}

output "workspace_status" {
  value = databricks_mws_workspaces.this.workspace_status
}

output "workspace_id" {
  value = databricks_mws_workspaces.this.workspace_id
}

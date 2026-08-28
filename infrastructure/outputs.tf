# Outputs for downstream skills/consumers go here as resources are added.

output "workspace_urls" {
  description = "Map of workspace slug -> workspace URL, for every entry in var.workspaces."
  value       = { for k, m in module.workspace : k => m.workspace_url }
}

output "workspace_statuses" {
  description = "Map of workspace slug -> workspace_status, for every entry in var.workspaces."
  value       = { for k, m in module.workspace : k => m.workspace_status }
}

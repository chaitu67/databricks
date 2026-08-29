output "group_id" {
  value = databricks_group.this.id
}

output "group_name" {
  value = databricks_group.this.display_name
}

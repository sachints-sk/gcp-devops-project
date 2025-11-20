output "db_private_ip" {
  value = google_sql_database_instance.instance.private_ip_address
}
output "cluster_name" {
  value = google_container_cluster.primary.name
}
output "cluster_location" {
  value = google_container_cluster.primary.location
}
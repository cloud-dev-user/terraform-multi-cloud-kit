output "instance_name" { value = google_sql_database_instance.this.name }
output "private_ip"    { value = google_sql_database_instance.this.private_ip_address }
output "connection_name" { value = google_sql_database_instance.this.connection_name }
output "db_secret_id"  { value = google_secret_manager_secret.db_password.secret_id }

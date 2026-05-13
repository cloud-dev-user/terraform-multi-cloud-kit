variable "project_id" { type = string }
variable "instance_name" { type = string }
variable "region" { type = string }
variable "database_version" { type = string; default = "POSTGRES_15" }
variable "tier" { type = string; default = "db-g1-small" }
variable "high_availability" { type = bool; default = true }
variable "disk_size" { type = number; default = 20 }
variable "private_network" { type = string }
variable "deletion_protection" { type = bool; default = true }
variable "point_in_time_recovery" { type = bool; default = true }
variable "backup_count" { type = number; default = 7 }
variable "databases" { type = list(string); default = [] }
variable "db_user" { type = string; default = "dbadmin" }
variable "database_flags" {
  type = list(object({ name = string; value = string }))
  default = []
}

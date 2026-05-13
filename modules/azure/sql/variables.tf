variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "server_name"         { type = string }
variable "admin_username"      { type = string; default = "sqladmin" }
variable "aad_admin_login"     { type = string }
variable "aad_admin_object_id" { type = string }
variable "sku_name"            { type = string; default = "GP_Gen5_2" }
variable "databases"           { type = list(string); default = [] }
variable "backup_retention_days" { type = number; default = 7 }
variable "allowed_subnet_ids"  { type = list(string); default = [] }
variable "key_vault_id"        { type = string; default = "" }
variable "tags"                { type = map(string); default = {} }

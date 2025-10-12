output "folder_id" {
  description = "ID of the created folder"
  value       = yandex_resourcemanager_folder.future_folder.id
}

output "network_id" {
  description = "ID of the created network"
  value       = yandex_vpc_network.future_network.id
}

output "medical_vm_internal_ip" {
  description = "Internal IP of Medical VM"
  value       = yandex_compute_instance.medical_vm.network_interface.0.ip_address
}

output "fintech_vm_internal_ip" {
  description = "Internal IP of Fintech VM"
  value       = yandex_compute_instance.fintech_vm.network_interface.0.ip_address
}

output "ai_vm_internal_ip" {
  description = "Internal IP of AI VM"
  value       = yandex_compute_instance.ai_vm.network_interface.0.ip_address
}

output "postgresql_cluster_fqdn" {
  description = "FQDN of PostgreSQL cluster"
  value       = yandex_mdb_postgresql_cluster.medical_db.host.0.fqdn
}

output "mysql_cluster_fqdn" {
  description = "FQDN of MySQL cluster"
  value       = yandex_mdb_mysql_cluster.finance_db.host.0.fqdn
}

output "ydb_database_path" {
  description = "Path to YDB database"
  value       = yandex_ydb_database_serverless.analytics_ydb.database_path
}

output "object_storage_bucket" {
  description = "Name of object storage bucket"
  value       = yandex_storage_bucket.data_lake.bucket
}

output "nat_instance_external_ip" {
  description = "External IP of NAT instance"
  value       = yandex_compute_instance.nat_instance.network_interface.0.nat_ip_address
}

output "route_table_id" {
  description = "ID of NAT route table"
  value       = yandex_vpc_route_table.nat_route_table.id
}
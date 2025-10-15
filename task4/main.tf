terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  zone = var.yc_zone
  token = var.yc_token
}

resource "yandex_resourcemanager_folder" "future_folder" {
  cloud_id    = var.yc_cloud_id
  name        = "future-2-0-${var.environment}"
  description = "Folder for Future 2.0 project"
}

# VNet
resource "yandex_vpc_network" "future_network" {
  name        = "future-network-${var.environment}"
  description = "Network for Future 2.0 infrastructure"
  folder_id   = yandex_resourcemanager_folder.future_folder.id
}

resource "yandex_vpc_subnet" "web_subnet" {
  name           = "web-subnet-${var.environment}"
  description    = "subnet web services"
  v4_cidr_blocks = ["192.168.1.0/24"]
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.future_network.id
  folder_id      = yandex_resourcemanager_folder.future_folder.id
}

resource "yandex_compute_instance" "nat_instance" {
  name        = "nat-instance-${var.environment}"
  platform_id = "standard-v3"
  folder_id   = yandex_resourcemanager_folder.future_folder.id
  zone        = var.yc_zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
      size     = 20
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.web_subnet.id
    nat        = true
    ip_address = "192.168.1.254"
  }

  metadata = {
    user-data = "#cloud-config"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_vpc_route_table" "nat_route_table" {
  name       = "nat-route-table-${var.environment}"
  network_id = yandex_vpc_network.future_network.id
  folder_id  = yandex_resourcemanager_folder.future_folder.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat_instance.network_interface.0.ip_address
  }
}

resource "yandex_vpc_subnet" "web_subnet_updated" {
  name           = "web-subnet-${var.environment}"
  description    = "subnet web services with NAT"
  v4_cidr_blocks = ["192.168.1.0/24"]
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.future_network.id
  folder_id      = yandex_resourcemanager_folder.future_folder.id
  route_table_id = yandex_vpc_route_table.nat_route_table.id

  lifecycle {
    ignore_changes = [
      name,
      description
    ]
  }
}

resource "yandex_vpc_subnet" "db_subnet" {
  name           = "db-subnet-${var.environment}"
  description    = "subnet for db"
  v4_cidr_blocks = ["192.168.2.0/24"]
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.future_network.id
  folder_id      = yandex_resourcemanager_folder.future_folder.id
}

resource "yandex_vpc_subnet" "analytics_subnet" {
  name           = "analytics-subnet-${var.environment}"
  description    = "subnet analytics"
  v4_cidr_blocks = ["192.168.3.0/24"]
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.future_network.id
  folder_id      = yandex_resourcemanager_folder.future_folder.id
}

#NSG
resource "yandex_vpc_security_group" "web_sg" {
  name        = "web-security-group-${var.environment}"
  description = "Security group for web services"
  network_id  = yandex_vpc_network.future_network.id
  folder_id   = yandex_resourcemanager_folder.future_folder.id

  ingress {
    protocol       = "TCP"
    description    = "SSH access"
    v4_cidr_blocks = [var.admin_ip]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP access"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS access"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "Application ports"
    v4_cidr_blocks = ["192.168.0.0/16"]
    port           = 8080
  }

  egress {
    protocol       = "ANY"
    description    = "Outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "db_sg" {
  name        = "db-security-group-${var.environment}"
  description = "Security group for databases"
  network_id  = yandex_vpc_network.future_network.id
  folder_id   = yandex_resourcemanager_folder.future_folder.id

  ingress {
    protocol       = "TCP"
    description    = "PostgreSQL access from web servers"
    v4_cidr_blocks = ["192.168.1.0/24"]
    port           = 5432
  }

  ingress {
    protocol       = "TCP"
    description    = "MySQL access from web servers"
    v4_cidr_blocks = ["192.168.1.0/24"]
    port           = 3306
  }

  ingress {
    protocol       = "TCP"
    description    = "Database access from analytics"
    v4_cidr_blocks = ["192.168.3.0/24"]
    port           = 5432
  }
}

#VM
resource "yandex_compute_instance" "medical_vm" {
  name        = "medical-vm-${var.environment}"
  platform_id = "standard-v3"
  folder_id   = yandex_resourcemanager_folder.future_folder.id
  zone        = var.yc_zone

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      size     = 50
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.web_subnet.id
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    user-data = "#cloud-config" #ssh key добавить
  }

  scheduling_policy {
    preemptible = var.environment != "prod"
  }
}

resource "yandex_compute_instance" "fintech_vm" {
  name        = "fintech-vm-${var.environment}"
  platform_id = "standard-v3"
  folder_id   = yandex_resourcemanager_folder.future_folder.id
  zone        = var.yc_zone

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk"
      size     = 50
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.web_subnet.id
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    user-data = "#cloud-config" #ssh key добавить
  }

  scheduling_policy {
    preemptible = var.environment != "prod"
  }
}

resource "yandex_compute_instance" "ai_vm" {
  name        = "ai-vm-${var.environment}"
  platform_id = "standard-v3" # Используем стандартную VM для избежания ошибок доступности GPU
  folder_id   = yandex_resourcemanager_folder.future_folder.id
  zone        = var.yc_zone

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vmcue7aajpmeo39kk" # Ubuntu 22.04
      size     = 100
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.web_subnet.id
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    user-data = "#cloud-config"#ssh key добавить
  }

  scheduling_policy {
    preemptible = var.environment != "prod"
  }
}

#DB
resource "yandex_mdb_postgresql_cluster" "medical_db" {
  name        = "medical-db-${var.environment}"
  environment = var.environment == "prod" ? "PRODUCTION" : "PRESTABLE"
  network_id  = yandex_vpc_network.future_network.id
  folder_id   = yandex_resourcemanager_folder.future_folder.id

  config {
    version = 15
    resources {
      resource_preset_id = "b2.medium"
      disk_type_id       = "network-ssd"
      disk_size          = 50
    }

    access {
      web_sql = true
    }

    postgresql_config = {
      max_connections                   = 100
      enable_parallel_hash              = true
      default_transaction_isolation     = "TRANSACTION_ISOLATION_READ_COMMITTED"
    }
  }

  host {
    zone      = var.yc_zone
    subnet_id = yandex_vpc_subnet.db_subnet.id
  }

  database {
    name  = "medicaldb"
    owner = var.db_admin_username
  }

  user {
    name     = var.db_admin_username
    password = var.db_admin_password
    permission {
      database_name = "medicaldb"
    }
  }

  security_group_ids = [yandex_vpc_security_group.db_sg.id]
}

resource "yandex_mdb_mysql_cluster" "finance_db" {
  name        = "finance-db-${var.environment}"
  environment = var.environment == "prod" ? "PRODUCTION" : "PRESTABLE"
  network_id  = yandex_vpc_network.future_network.id
  folder_id   = yandex_resourcemanager_folder.future_folder.id
  version     = "8.0"

  resources {
    resource_preset_id = "b2.medium"
    disk_type_id       = "network-ssd"
    disk_size          = 50
  }

  host {
    zone      = var.yc_zone
    subnet_id = yandex_vpc_subnet.db_subnet.id
  }

  database {
    name = "financedb"
  }

  user {
    name     = var.db_admin_username
    password = var.db_admin_password
    permission {
      database_name = "financedb"
      roles         = ["ALL"]
    }
  }

  security_group_ids = [yandex_vpc_security_group.db_sg.id]
}

resource "yandex_ydb_database_serverless" "analytics_ydb" {
  name      = "analytics-ydb-${var.environment}"
  folder_id = yandex_resourcemanager_folder.future_folder.id

  serverless_database {
    storage_size_limit = 50
  }
}

resource "yandex_storage_bucket" "data_lake" {
  bucket     = "future-datalake-${var.environment}-${random_integer.bucket_suffix.result}"
  folder_id  = yandex_resourcemanager_folder.future_folder.id
  access_key = yandex_iam_service_account_static_access_key.sa_storage_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_storage_key.secret_key

  max_size = 5368709120 # 5 GB

  anonymous_access_flags {
    read = false
    list = false
  }
}

resource "yandex_iam_service_account" "sa_storage" {
  folder_id = yandex_resourcemanager_folder.future_folder.id
  name      = "sa-storage-${var.environment}"
}

resource "yandex_iam_service_account_static_access_key" "sa_storage_key" {
  service_account_id = yandex_iam_service_account.sa_storage.id
}

resource "yandex_resourcemanager_folder_iam_member" "sa_storage_permissions" {
  folder_id = yandex_resourcemanager_folder.future_folder.id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa_storage.id}"
}

resource "random_integer" "bucket_suffix" {
  min = 1000
  max = 9999
}
variable "environment" {
  description = "environment (dev, staging, prod)?"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "must be dev, staging, or prod."
  }
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  sensitive   = true
  default     = "fake-TtRdxt2YvRR5aPZv"
}

variable "yc_zone" {
  description = "Yandex Cloud zone"
  type        = string
  default     = "ru-central1-a"
}

variable "yc_token" {
  description = "Yandex Cloud token"
  type        = string
  default     = "fake-3v6DkxHCvhRDuxyg"
}

variable "admin_ip" {
  description = "Admin IP address for SSH access"
  type        = string
  default     = "127.0.0.1"
}

variable "db_admin_username" {
  description = "Admin username for databases"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "db_admin_password" {
  description = "Admin password for databases"
  type        = string
  sensitive   = true
  default     = "whFAKWD0XrPKH4z5KtPGCaotEJfuV2wA"
}
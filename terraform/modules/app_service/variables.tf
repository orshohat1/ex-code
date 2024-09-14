variable "app_service_name" {
  description = "Name of the App Service"
  type        = string
}

variable "location" {
  description = "Location of the App Service"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the App Service"
  type        = string
}

variable "sku_name" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "P1v2"
}

variable "vnet_subnet_id" {
  description = "Subnet ID for VNet Integration"
  type        = string
}

variable "app_settings" {
  description = "App settings for the App Service"
  type        = map(string)
  default     = {}
}

variable "identity_type" {
  description = "Type of managed identity for App Service"
  type        = string
  default     = "SystemAssigned"
}
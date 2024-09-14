variable "location" {
  type        = string
  default     = "westeurope"
  description = "Deployment location in Azure"
}

variable "resource_group_name" {
  type        = string
  default     = "test-rg"
  description = "Resource Group name"
}

variable "appserivce_subnet_name" {
  description = "Specifies the name of the app service subnet"
  default     = "appservice"
  type        = string
}

variable "pe_subnet_name" {
  description = "Specifies the name of the app service subnet"
  default     = "pe"
  type        = string
}

variable "mongodb_atlas_public_key" {
  type = string
}

variable "mongodb_atlas_private_key" {
  type = string
}
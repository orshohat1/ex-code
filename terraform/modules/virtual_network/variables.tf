variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "location" {
  description = "Location in which to deploy the network"
  type        = string
}

variable "vnet_name" {
  description = "VNET name"
  type        = string
}

variable "address_space" {
  description = "VNET address space"
  default     = ["10.1.0.0/16"]
  type        = list(string)
}

variable "subnets" {
  description = "A list of subnets to create"
  type = list(object({
    name             = string
    address_prefixes = list(string)
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
    service_endpoints = optional(list(string))
  }))
}


variable "tags" {
  description = "(Optional) Specifies the tags of the storage account"
  default     = {}
}

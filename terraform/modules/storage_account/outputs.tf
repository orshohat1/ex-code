output "name" {
  description = "Specifies the name of the storage account"
  value       = azurerm_storage_account.storage_account.name
}

output "id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.storage_account.id
}
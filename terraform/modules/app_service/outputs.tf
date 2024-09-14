output "app_service_id" {
  description = "The ID of the App Service"
  value       = azurerm_linux_web_app.app_service.id
}

output "identity_principal_id" {
  description = "The principal ID of the App Service Managed Identity"
  value       = azurerm_linux_web_app.app_service.identity[0].principal_id
}

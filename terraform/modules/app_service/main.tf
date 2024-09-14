# Create the App Service Plan
resource "azurerm_service_plan" "app_service_plan" {
  name                = "${var.app_service_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  os_type             = "Linux"
}

resource "azurerm_linux_web_app" "app_service" {
  name                = var.app_service_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  app_settings = merge(var.app_settings, {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  })

  identity {
    type = var.identity_type
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}

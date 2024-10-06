
# create the service plan
resource "azurerm_service_plan" "webapp_service_plan" {
  name                = local.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type = "Linux"
  sku_name = "B1"
}

# create the app service for python app
resource "azurerm_linux_web_app" "webapp" {
  name                = local.app_service_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id = azurerm_service_plan.app_service_plan.id
  site_config {
    linux_fx_version = "PYTHON|3.11"
  }
  depends_on = [ azurerm_service_plan.webapp_service_plan ]

  # enable managed identity
    identity {
        type = "SystemAssigned"
    }
}
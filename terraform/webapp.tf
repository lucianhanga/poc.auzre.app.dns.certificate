
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
  service_plan_id = azurerm_service_plan.webapp_service_plan.id
  site_config {
    always_on = false
    application_stack {
        python_version = "3.11"
    }
  }
  depends_on = [ azurerm_service_plan.webapp_service_plan ]

  # enable managed identity
    identity {
        type = "SystemAssigned"
    }
}


# Create a CNAME record for the custom domain (optional, skip if managed externally)
resource "azurerm_dns_cname_record" "custom_domain_cname" {
  name                = "www"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  record              = azurerm_linux_web_app.webapp.default_hostname  # Point to Azure Web App's default domain
  
  depends_on = [ azurerm_linux_web_app.webapp, azurerm_dns_zone.dns_zone ]
}

# Output the defaul webapp URL
output "webapp_url" {
  value = azurerm_linux_web_app.webapp.default_hostname
}

# associate the custom domain with the webapp
resource "azurerm_app_service_custom_hostname_binding" "custom_domain_binding" {
  hostname = azurerm_dns_cname_record.custom_domain_cname.fqdn
  app_service_name = azurerm_linux_web_app.webapp.name
  resource_group_name = var.resource_group_name
  depends_on = [ azurerm_dns_cname_record.custom_domain_cname ]  
}

# Output the custom domain URL
output "custom_domain_url" {
  value = azurerm_dns_cname_record.custom_domain_cname.fqdn
}



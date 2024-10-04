resource "azurerm_dns_zone" "dns_zone" {
  name                = var.domain_name
  resource_group_name = var.resource_group_name
}

# output the DNS servers for the zone
output "dns_servers" {
  value = azurerm_dns_zone.dns_zone.name_servers
}

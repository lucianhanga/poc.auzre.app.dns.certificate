# create a key vault where to store the username and password for the MySQL server
resource "azurerm_key_vault" "key_vault" {
  name                = local.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id            = var.tenant_id
  sku_name            = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "terraform" {
  scope = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets Officer" 
  principal_id = var.object_id

  depends_on = [ azurerm_key_vault.key_vault ]
}

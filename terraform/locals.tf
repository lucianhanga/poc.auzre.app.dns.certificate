locals {
  key_vault_name        = "kv-${var.project_name}${var.project_suffix}" # the name of the key vault
  app_service_plan_name = "asp-${var.project_name}${var.project_suffix}" # the name of the app service plan
  app_service_name      = "app-${var.project_name}${var.project_suffix}" # the name of the app service
}

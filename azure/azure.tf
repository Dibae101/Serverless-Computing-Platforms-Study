provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "example-resources"
  location = "East US"
}

resource "azurerm_application_insights" "ai" {
  name                = "example-ai"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "example-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
}

resource "azurerm_key_vault" "kv" {
  name                = "example-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "standard"
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "example-secret"
  value        = "my-secret-value"
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_function_app" "fa" {
  name                       = "example-function"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  os_type                    = "linux"
  runtime_stack              = "python"

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.ai.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.ai.connection_string
    "KEY_VAULT_SECRET_URI"           = azurerm_key_vault_secret.secret.id
  }

  site_config {
    application_insights {
      connection_string = azurerm_application_insights.ai.connection_string
    }
  }
}

resource "azurerm_app_service_plan" "asp" {
  name                = "example-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_storage_account" "sa" {
  name                     = "examplestorageacc"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_monitor_diagnostic_setting" "ds" {
  name               = "example-ds"
  target_resource_id = azurerm_function_app.fa.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  log {
    category = "FunctionAppLogs"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 7
    }
  }
}
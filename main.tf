terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.43.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "main" {
  name = "Cohort25_ChiBha_Workshop_M12_Pt2"
}

resource "azurerm_service_plan" "main" {
  name                = "chibha-terraformed-asp"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "example" {
  name                = "chibha-terraformed-app"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image     = "corndeldevopscourse/mod12app"
      docker_image_tag = "latest"
    }
  }

  app_settings = {
    "CONNECTION_STRING" = "Server=tcp:chibha-non-iac-sqlserver.database.windows.net,1433;Initial Catalog=chibha-non-iac-db;Persist Security Info=False;User ID=dbadmin;Password=${var.database_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;",
    "DEPLOYMENT_METHOD" = "Terraform",
    "SCM_DO_BUILD_DURING_DEPLOYMENT" : "True"
  }
}

resource "azurerm_mssql_server" "main" {
  name                         = "chibha-non-iac-sqlserver"
  resource_group_name          = data.azurerm_resource_group.main.name
  location                     = data.azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "dbadmin"
  administrator_login_password = var.database_password
}

resource "azurerm_mssql_database" "main" {
  name           = "chibha-non-iac-db"
  server_id      = azurerm_mssql_server.main.id
  sku_name       = "Basic"

  lifecycle {
    prevent_destroy = true
  }
}
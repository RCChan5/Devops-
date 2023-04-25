// Tags
locals {
  tags = {
    owner       = var.tag_department
    region      = var.tag_region
    environment = var.environment
  }
}

// Existing Resources

/// Subscription ID

data "azurerm_subscription" "current" {
}

// Random Suffix Generator

resource "random_integer" "deployment_id_suffix" {
  min = 100
  max = 999
}

// Resource Group

resource "azurerm_resource_group" "rg" {
  name     = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-rg"
  location = var.location

  tags = local.tags
}


// Storage Account

resource "azurerm_storage_account" "storage" {
  name                     = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}st"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.tags
}


/////////////////////////////////////////////////////////////CosmosDB

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "db" {
  name                = "tfex-cosmos-db-${random_integer.ri.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "eastus"
    failover_priority = 1
  }

  geo_location {
    location          = "westus"
    failover_priority = 0
  }
}


/////////////////////////////////////////////////// azure ml

data "azurerm_client_config" "current" {}



resource "azurerm_application_insights" "ai" {
  name                = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-ai"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_key_vault" "kv" {
  name                = "${var.class_name}-${var.student_name}-${random_integer.deployment_id_suffix.result}-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}



resource "azurerm_machine_learning_workspace" "mlw" {
  name                    = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-mlw"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  application_insights_id = azurerm_application_insights.ai.id
  key_vault_id            = azurerm_key_vault.kv.id
  storage_account_id      = azurerm_storage_account.storage.id

  identity {
    type = "SystemAssigned"
  }
}
/////////////////////////////////////// alexa 
resource "azurerm_bot_channels_registration" "bcr" {
  name                = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-bcr"
  location            = "global"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "F0"
  microsoft_app_id    = data.azurerm_client_config.current.client_id
}

resource "azurerm_bot_channel_alexa" "bca" {
  bot_name            = azurerm_bot_channels_registration.bcr.name
  location            = azurerm_bot_channels_registration.bcr.location
  resource_group_name = azurerm_resource_group.rg.name
  skill_id            = "${random_integer.deployment_id_suffix.result}-amzn1.ask.skill.00000000-0000-0000-0000-000000000000"
}

/////////////////////////////////////////// Power Bi
resource "azurerm_powerbi_embedded" "powerbi" {
  name                = "${var.class_name}${var.student_name}powerbi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "A1"
  administrators      = ["rchan5@uncc.edu"]
}
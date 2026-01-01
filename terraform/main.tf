# =============================================================================
# LLM AI Gateway - Core Infrastructure (Resource Group & Log Analytics)
# =============================================================================

# -----------------------------------------------------------------------------
# Random Suffix for Globally Unique Names
# -----------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  # Unique suffix for globally unique resource names
  suffix = random_string.suffix.result

  # Merge environment tag
  common_tags = merge(var.tags, {
    environment = var.environment
  })
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location_primary
  tags     = local.common_tags
}

# -----------------------------------------------------------------------------
# Log Analytics Workspace (for Observability)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-llm-gateway-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

# -----------------------------------------------------------------------------
# Application Insights (for APIM Monitoring)
# -----------------------------------------------------------------------------

resource "azurerm_application_insights" "main" {
  name                = "appi-llm-gateway-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = local.common_tags
}

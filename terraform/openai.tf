# =============================================================================
# LLM AI Gateway - Azure OpenAI Resources
# =============================================================================
# Deploys Azure OpenAI in two regions (westus, westus2) for load balancing
# and high availability. Uses Managed Identity for secure authentication.
# =============================================================================

# -----------------------------------------------------------------------------
# User Assigned Managed Identity (for APIM to access Azure OpenAI)
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "apim" {
  name                = "id-apim-llm-gateway-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# -----------------------------------------------------------------------------
# Azure OpenAI - Primary Region (westus)
# -----------------------------------------------------------------------------

resource "azurerm_cognitive_account" "openai_primary" {
  name                  = "oai-llm-gateway-primary-${local.suffix}"
  location              = var.location_primary
  resource_group_name   = azurerm_resource_group.main.name
  kind                  = "OpenAI"
  sku_name              = var.openai_sku
  custom_subdomain_name = "oai-llm-gateway-primary-${local.suffix}"
  tags                  = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = "Allow"
  }
}

# Model Deployments - Primary Region
resource "azurerm_cognitive_deployment" "primary" {
  for_each = { for d in var.openai_deployments : d.name => d }

  name                 = each.value.name
  cognitive_account_id = azurerm_cognitive_account.openai_primary.id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.version
  }

  sku {
    name     = "Standard"
    capacity = each.value.capacity
  }
}

# -----------------------------------------------------------------------------
# Azure OpenAI - Secondary Region (westus2)
# -----------------------------------------------------------------------------

resource "azurerm_cognitive_account" "openai_secondary" {
  name                  = "oai-llm-gateway-secondary-${local.suffix}"
  location              = var.location_secondary
  resource_group_name   = azurerm_resource_group.main.name
  kind                  = "OpenAI"
  sku_name              = var.openai_sku
  custom_subdomain_name = "oai-llm-gateway-secondary-${local.suffix}"
  tags                  = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = "Allow"
  }
}

# Model Deployments - Secondary Region
resource "azurerm_cognitive_deployment" "secondary" {
  for_each = { for d in var.openai_deployments : d.name => d }

  name                 = each.value.name
  cognitive_account_id = azurerm_cognitive_account.openai_secondary.id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.version
  }

  sku {
    name     = "Standard"
    capacity = each.value.capacity
  }
}

# -----------------------------------------------------------------------------
# Role Assignments - Grant APIM Managed Identity access to Azure OpenAI
# -----------------------------------------------------------------------------

# Cognitive Services OpenAI User role for primary region
resource "azurerm_role_assignment" "apim_openai_primary" {
  scope                = azurerm_cognitive_account.openai_primary.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.apim.principal_id
}

# Cognitive Services OpenAI User role for secondary region
resource "azurerm_role_assignment" "apim_openai_secondary" {
  scope                = azurerm_cognitive_account.openai_secondary.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.apim.principal_id
}

# -----------------------------------------------------------------------------
# Diagnostic Settings for Azure OpenAI
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "openai_primary" {
  name                       = "diag-openai-primary"
  target_resource_id         = azurerm_cognitive_account.openai_primary.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "RequestResponse"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "openai_secondary" {
  name                       = "diag-openai-secondary"
  target_resource_id         = azurerm_cognitive_account.openai_secondary.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "RequestResponse"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

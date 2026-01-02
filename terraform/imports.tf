# =============================================================================
# Terraform Import Blocks
# =============================================================================
# These import blocks will import existing Azure resources into Terraform state.
# Run `terraform plan` to see the import preview, then `terraform apply` to import.
# After successful import, you can delete this file.
# =============================================================================

locals {
  subscription_id = "ecaa20e2-0528-4f9f-91fd-73fc465828a1"
  rg_name         = "rg-llm-gateway"
  existing_suffix = "0jdcfd"
}

# Resource Group
import {
  to = azurerm_resource_group.main
  id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg_name}"
}

# Log Analytics Workspace
import {
  to = azurerm_log_analytics_workspace.main
  id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.OperationalInsights/workspaces/law-llm-gateway-${local.existing_suffix}"
}

# Application Insights
import {
  to = azurerm_application_insights.main
  id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.Insights/components/appi-llm-gateway-${local.existing_suffix}"
}

# User Assigned Managed Identity
import {
  to = azurerm_user_assigned_identity.apim
  id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-apim-llm-gateway-${local.existing_suffix}"
}

# Azure OpenAI - Primary (westus)
import {
  to = azurerm_cognitive_account.openai_primary
  id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.CognitiveServices/accounts/oai-llm-gateway-primary-${local.existing_suffix}"
}

# Azure OpenAI - Secondary (eastus)
import {
  to = azurerm_cognitive_account.openai_secondary
  id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.CognitiveServices/accounts/oai-llm-gateway-secondary-${local.existing_suffix}"
}

# OpenAI Deployment - Primary gpt-4o-mini
import {
  to = azurerm_cognitive_deployment.primary["gpt-4o-mini"]
  id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.CognitiveServices/accounts/oai-llm-gateway-primary-${local.existing_suffix}/deployments/gpt-4o-mini"
}

# OpenAI Deployment - Secondary gpt-4o-mini
import {
  to = azurerm_cognitive_deployment.secondary["gpt-4o-mini"]
  id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg_name}/providers/Microsoft.CognitiveServices/accounts/oai-llm-gateway-secondary-${local.existing_suffix}/deployments/gpt-4o-mini"
}

# API Management - SKIPPED: Resource is in Failed state, needs to be deleted and recreated
# Delete with: az apim delete --name apim-llm-gateway-0jdcfd --resource-group rg-llm-gateway --yes

# Random string suffix - needs special handling
# The random_string resource needs to be imported with the actual value
import {
  to = random_string.suffix
  id = "${local.existing_suffix}"
}

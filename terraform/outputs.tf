# =============================================================================
# LLM AI Gateway - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# API Management Outputs
# -----------------------------------------------------------------------------

output "apim_name" {
  description = "Name of the API Management instance"
  value       = local.apim_name
}

output "apim_gateway_url" {
  description = "Gateway URL of the API Management instance"
  value       = local.apim_gateway_url
}

output "apim_developer_portal_url" {
  description = "Developer portal URL"
  value       = local.apim_developer_portal_url
}

output "apim_management_api_url" {
  description = "Management API URL"
  value       = local.apim_management_api_url
}

output "openai_api_endpoint" {
  description = "Full endpoint for Azure OpenAI API through APIM"
  value       = "${local.apim_gateway_url}/openai"
}

# -----------------------------------------------------------------------------
# Azure OpenAI Outputs
# -----------------------------------------------------------------------------

output "openai_primary_endpoint" {
  description = "Endpoint for primary Azure OpenAI instance"
  value       = azurerm_cognitive_account.openai_primary.endpoint
}

output "openai_secondary_endpoint" {
  description = "Endpoint for secondary Azure OpenAI instance"
  value       = azurerm_cognitive_account.openai_secondary.endpoint
}

output "openai_primary_id" {
  description = "Resource ID of primary Azure OpenAI instance"
  value       = azurerm_cognitive_account.openai_primary.id
}

output "openai_secondary_id" {
  description = "Resource ID of secondary Azure OpenAI instance"
  value       = azurerm_cognitive_account.openai_secondary.id
}

# -----------------------------------------------------------------------------
# Azure Managed Redis Outputs
# -----------------------------------------------------------------------------

output "redis_hostname" {
  description = "Hostname of the Azure Managed Redis cluster"
  value       = "${azapi_resource.redis.name}.${azurerm_resource_group.main.location}.redis.azure.net"
}

output "redis_id" {
  description = "Resource ID of the Azure Managed Redis cluster"
  value       = azapi_resource.redis.id
}

output "redis_database_id" {
  description = "Resource ID of the Azure Managed Redis database"
  value       = azapi_resource.redis_database.id
}

output "redis_primary_access_key" {
  description = "Primary access key for Azure Managed Redis (sensitive)"
  value       = jsondecode(data.azapi_resource_action.redis_keys.output).primaryKey
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Observability Outputs
# -----------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Identity Outputs
# -----------------------------------------------------------------------------

output "apim_managed_identity_client_id" {
  description = "Client ID of the APIM managed identity"
  value       = azurerm_user_assigned_identity.apim.client_id
}

output "apim_managed_identity_principal_id" {
  description = "Principal ID of the APIM managed identity"
  value       = azurerm_user_assigned_identity.apim.principal_id
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# -----------------------------------------------------------------------------
# Azure Portal Links
# -----------------------------------------------------------------------------

output "azure_portal_resource_group_url" {
  description = "Direct link to the resource group in Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_resource_group.main.id}"
}

output "azure_portal_apim_url" {
  description = "Direct link to APIM in Azure Portal"
  value       = "https://portal.azure.com/#@/resource${local.apim_id}"
}

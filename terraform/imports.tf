# Import existing resource group
import {
  to = azurerm_resource_group.main
  id = "/subscriptions/ecaa20e2-0528-4f9f-91fd-73fc465828a1/resourceGroups/rg-llm-gateway"
}

# Import APIM sub-resources that were created in previous run
locals {
  sub_id   = "ecaa20e2-0528-4f9f-91fd-73fc465828a1"
  apim_rg  = "rg-prod-core"
  apim_svc = "apim-raly"
}

import {
  to = azurerm_api_management_logger.appinsights
  id = "/subscriptions/${local.sub_id}/resourceGroups/${local.apim_rg}/providers/Microsoft.ApiManagement/service/${local.apim_svc}/loggers/appinsights-logger"
}

import {
  to = azurerm_api_management_named_value.redis_endpoint
  id = "/subscriptions/${local.sub_id}/resourceGroups/${local.apim_rg}/providers/Microsoft.ApiManagement/service/${local.apim_svc}/namedValues/redis-endpoint"
}

import {
  to = azurerm_api_management_named_value.managed_identity_client_id
  id = "/subscriptions/${local.sub_id}/resourceGroups/${local.apim_rg}/providers/Microsoft.ApiManagement/service/${local.apim_svc}/namedValues/managed-identity-client-id"
}

import {
  to = azurerm_api_management_named_value.openai_primary_endpoint
  id = "/subscriptions/${local.sub_id}/resourceGroups/${local.apim_rg}/providers/Microsoft.ApiManagement/service/${local.apim_svc}/namedValues/openai-primary-endpoint"
}

import {
  to = azurerm_api_management_named_value.openai_secondary_endpoint
  id = "/subscriptions/${local.sub_id}/resourceGroups/${local.apim_rg}/providers/Microsoft.ApiManagement/service/${local.apim_svc}/namedValues/openai-secondary-endpoint"
}

import {
  to = azurerm_api_management_backend.openai_primary
  id = "/subscriptions/${local.sub_id}/resourceGroups/${local.apim_rg}/providers/Microsoft.ApiManagement/service/${local.apim_svc}/backends/openai-backend-primary"
}

import {
  to = azurerm_api_management_backend.openai_secondary
  id = "/subscriptions/${local.sub_id}/resourceGroups/${local.apim_rg}/providers/Microsoft.ApiManagement/service/${local.apim_svc}/backends/openai-backend-secondary"
}

import {
  to = azurerm_api_management_product.openai
  id = "/subscriptions/${local.sub_id}/resourceGroups/${local.apim_rg}/providers/Microsoft.ApiManagement/service/${local.apim_svc}/products/openai-product"
}

import {
  to = azurerm_api_management_api.openai
  id = "/subscriptions/${local.sub_id}/resourceGroups/${local.apim_rg}/providers/Microsoft.ApiManagement/service/${local.apim_svc}/apis/azure-openai-api;rev=1"
}

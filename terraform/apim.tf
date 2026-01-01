# =============================================================================
# LLM AI Gateway - Azure API Management
# =============================================================================
# Configures APIM as a gateway for Azure OpenAI with:
# - Load balancing across two regions (round-robin with circuit breaker)
# - Rate limiting and token limits
# - Managed Identity authentication to Azure OpenAI
# - Caching with Redis
# - Full observability with Application Insights
# =============================================================================

# -----------------------------------------------------------------------------
# API Management Instance
# -----------------------------------------------------------------------------

resource "azurerm_api_management" "main" {
  name                = "${var.apim_name}-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = "${var.apim_sku_name}_${var.apim_sku_capacity}"
  tags                = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.apim.id]
  }

  depends_on = [
    azurerm_user_assigned_identity.apim
  ]
}

# -----------------------------------------------------------------------------
# Application Insights Logger
# -----------------------------------------------------------------------------

resource "azurerm_api_management_logger" "appinsights" {
  name                = "appinsights-logger"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  resource_id         = azurerm_application_insights.main.id

  application_insights {
    instrumentation_key = azurerm_application_insights.main.instrumentation_key
  }

  depends_on = [
    azurerm_api_management.main,
    azurerm_application_insights.main
  ]
}

# -----------------------------------------------------------------------------
# Redis Enterprise Named Values (for semantic caching in policies)
# -----------------------------------------------------------------------------
# Note: Azure Managed Redis Enterprise uses a different connection model.
# The APIM built-in Redis cache doesn't support Enterprise tier directly.
# Semantic caching is implemented via custom policy logic using send-request.

resource "azurerm_api_management_named_value" "redis_endpoint" {
  name                = "redis-enterprise-endpoint"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "redis-enterprise-endpoint"
  value               = "https://${azurerm_redis_enterprise_cluster.main.hostname}:10000"
  secret              = false

  depends_on = [
    azurerm_api_management.main,
    azurerm_redis_enterprise_cluster.main
  ]
}

resource "azurerm_api_management_named_value" "redis_password" {
  name                = "redis-enterprise-password"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "redis-enterprise-password"
  value               = azurerm_redis_enterprise_database.main.primary_access_key
  secret              = true

  depends_on = [
    azurerm_api_management.main,
    azurerm_redis_enterprise_database.main
  ]
}

# -----------------------------------------------------------------------------
# Named Values (for policy configuration)
# -----------------------------------------------------------------------------

resource "azurerm_api_management_named_value" "managed_identity_client_id" {
  name                = "managed-identity-client-id"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "managed-identity-client-id"
  value               = azurerm_user_assigned_identity.apim.client_id

  depends_on = [azurerm_api_management.main]
}

resource "azurerm_api_management_named_value" "openai_primary_endpoint" {
  name                = "openai-primary-endpoint"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "openai-primary-endpoint"
  value               = azurerm_cognitive_account.openai_primary.endpoint

  depends_on = [azurerm_api_management.main]
}

resource "azurerm_api_management_named_value" "openai_secondary_endpoint" {
  name                = "openai-secondary-endpoint"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "openai-secondary-endpoint"
  value               = azurerm_cognitive_account.openai_secondary.endpoint

  depends_on = [azurerm_api_management.main]
}

# -----------------------------------------------------------------------------
# Backend Pool for Load Balancing
# -----------------------------------------------------------------------------

resource "azurerm_api_management_backend" "openai_primary" {
  name                = "openai-backend-primary"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  protocol            = "http"
  url                 = "${azurerm_cognitive_account.openai_primary.endpoint}openai"
  description         = "Azure OpenAI - Primary Region (${var.location_primary})"

  depends_on = [
    azurerm_api_management.main,
    azurerm_cognitive_account.openai_primary,
    azurerm_role_assignment.apim_openai_primary
  ]
}

resource "azurerm_api_management_backend" "openai_secondary" {
  name                = "openai-backend-secondary"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  protocol            = "http"
  url                 = "${azurerm_cognitive_account.openai_secondary.endpoint}openai"
  description         = "Azure OpenAI - Secondary Region (${var.location_secondary})"

  depends_on = [
    azurerm_api_management.main,
    azurerm_cognitive_account.openai_secondary,
    azurerm_role_assignment.apim_openai_secondary
  ]
}

# Note: Backend pool/load balancing is implemented via APIM policy using
# round-robin with retry logic between the two backend endpoints.
# The azurerm provider doesn't support the pool block directly.

# -----------------------------------------------------------------------------
# OpenAI API Product
# -----------------------------------------------------------------------------

resource "azurerm_api_management_product" "openai" {
  product_id            = "openai-product"
  api_management_name   = azurerm_api_management.main.name
  resource_group_name   = azurerm_resource_group.main.name
  display_name          = "Azure OpenAI API"
  description           = "Access to Azure OpenAI models through the LLM Gateway"
  subscription_required = true
  approval_required     = true
  published             = true
  terms                 = "By subscribing, you agree to the usage policies and rate limits."

  depends_on = [azurerm_api_management.main]
}

# -----------------------------------------------------------------------------
# OpenAI API Definition
# -----------------------------------------------------------------------------

resource "azurerm_api_management_api" "openai" {
  name                  = "azure-openai-api"
  api_management_name   = azurerm_api_management.main.name
  resource_group_name   = azurerm_resource_group.main.name
  revision              = "1"
  display_name          = "Azure OpenAI API"
  path                  = "openai"
  protocols             = ["https"]
  service_url           = "https://placeholder.openai.azure.com/openai"
  subscription_required = true

  subscription_key_parameter_names {
    header = "api-key"
    query  = "subscription-key"
  }

  depends_on = [azurerm_api_management.main]
}

# Link API to Product
resource "azurerm_api_management_product_api" "openai" {
  api_name            = azurerm_api_management_api.openai.name
  product_id          = azurerm_api_management_product.openai.product_id
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [
    azurerm_api_management_api.openai,
    azurerm_api_management_product.openai
  ]
}

# -----------------------------------------------------------------------------
# API Operations
# -----------------------------------------------------------------------------

resource "azurerm_api_management_api_operation" "chat_completions" {
  operation_id        = "chat-completions"
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Creates a completion for the chat message"
  method              = "POST"
  url_template        = "/deployments/{deployment-id}/chat/completions"
  description         = "Creates a model response for the given chat conversation."

  template_parameter {
    name        = "deployment-id"
    required    = true
    type        = "string"
    description = "Deployment ID of the model"
  }

  request {
    description = "Chat completion request"

    query_parameter {
      name     = "api-version"
      required = true
      type     = "string"
    }
  }

  response {
    status_code = 200
    description = "OK"
  }

  depends_on = [azurerm_api_management_api.openai]
}

resource "azurerm_api_management_api_operation" "completions" {
  operation_id        = "completions"
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Creates a completion"
  method              = "POST"
  url_template        = "/deployments/{deployment-id}/completions"
  description         = "Creates a completion for the provided prompt and parameters."

  template_parameter {
    name        = "deployment-id"
    required    = true
    type        = "string"
    description = "Deployment ID of the model"
  }

  request {
    description = "Completion request"

    query_parameter {
      name     = "api-version"
      required = true
      type     = "string"
    }
  }

  response {
    status_code = 200
    description = "OK"
  }

  depends_on = [azurerm_api_management_api.openai]
}

resource "azurerm_api_management_api_operation" "embeddings" {
  operation_id        = "embeddings"
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Get embeddings"
  method              = "POST"
  url_template        = "/deployments/{deployment-id}/embeddings"
  description         = "Get a vector representation of a given input."

  template_parameter {
    name        = "deployment-id"
    required    = true
    type        = "string"
    description = "Deployment ID of the model"
  }

  request {
    description = "Embedding request"

    query_parameter {
      name     = "api-version"
      required = true
      type     = "string"
    }
  }

  response {
    status_code = 200
    description = "OK"
  }

  depends_on = [azurerm_api_management_api.openai]
}

resource "azurerm_api_management_api_operation" "images_generations" {
  operation_id        = "images-generations"
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Creates an image"
  method              = "POST"
  url_template        = "/deployments/{deployment-id}/images/generations"
  description         = "Creates an image given a prompt."

  template_parameter {
    name        = "deployment-id"
    required    = true
    type        = "string"
    description = "Deployment ID of the model"
  }

  request {
    description = "Image generation request"

    query_parameter {
      name     = "api-version"
      required = true
      type     = "string"
    }
  }

  response {
    status_code = 200
    description = "OK"
  }

  depends_on = [azurerm_api_management_api.openai]
}

# -----------------------------------------------------------------------------
# API-level Policy (Load Balancing, Rate Limiting, Caching, Auth)
# -----------------------------------------------------------------------------

resource "azurerm_api_management_api_policy" "openai" {
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = templatefile("${path.module}/policies/openai-api-policy.xml", {
    rate_limit_calls           = var.rate_limit_calls
    rate_limit_period          = var.rate_limit_period
    token_limit_bandwidth      = var.token_limit_per_minute * 4
    managed_identity_client_id = azurerm_user_assigned_identity.apim.client_id
    backend_primary_name       = azurerm_api_management_backend.openai_primary.name
    backend_secondary_name     = azurerm_api_management_backend.openai_secondary.name
  })

  depends_on = [
    azurerm_api_management_api.openai,
    azurerm_api_management_backend.openai_primary,
    azurerm_api_management_backend.openai_secondary,
    azurerm_api_management_named_value.redis_endpoint
  ]
}

# -----------------------------------------------------------------------------
# Diagnostic Settings for APIM
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "apim" {
  name                       = "diag-apim"
  target_resource_id         = azurerm_api_management.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "GatewayLogs"
  }

  enabled_log {
    category = "WebSocketConnectionLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }

  depends_on = [azurerm_api_management.main]
}

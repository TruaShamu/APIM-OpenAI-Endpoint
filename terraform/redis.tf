# =============================================================================
# LLM AI Gateway - Azure Managed Redis
# =============================================================================
# Provides semantic caching with vector search using RediSearch module.
# Azure Managed Redis (preview) supports RediSearch for similarity search.
# Uses azapi provider since azurerm doesn't support Balanced/Memory SKUs yet.
# =============================================================================

# -----------------------------------------------------------------------------
# Azure Managed Redis Cluster
# -----------------------------------------------------------------------------

resource "azapi_resource" "redis" {
  type      = "Microsoft.Cache/redisEnterprise@2024-09-01-preview"
  name      = "redis${local.suffix}"
  location  = azurerm_resource_group.main.location
  parent_id = azurerm_resource_group.main.id

  body = {
    sku = {
      name = var.redis_sku
      # Note: Balanced_B0 doesn't support capacity parameter
    }
    properties = {
      minimumTlsVersion = "1.2"
    }
  }

  tags = local.common_tags

  depends_on = [azurerm_resource_group.main]
}

# -----------------------------------------------------------------------------
# Azure Managed Redis Database with RediSearch
# -----------------------------------------------------------------------------

resource "azapi_resource" "redis_database" {
  type      = "Microsoft.Cache/redisEnterprise/databases@2024-09-01-preview"
  name      = "default"
  parent_id = azapi_resource.redis.id

  body = {
    properties = {
      clientProtocol   = "Encrypted"
      clusteringPolicy = "EnterpriseCluster"
      evictionPolicy   = "NoEviction"
      port             = 10000
      modules = [
        {
          name = "RediSearch"
        }
      ]
    }
  }

  response_export_values = ["properties.accessKeysAuthentication"]

  depends_on = [azapi_resource.redis]
}

# -----------------------------------------------------------------------------
# Data source to get Redis access keys
# -----------------------------------------------------------------------------

data "azapi_resource_action" "redis_keys" {
  type                   = "Microsoft.Cache/redisEnterprise/databases@2024-09-01-preview"
  resource_id            = azapi_resource.redis_database.id
  action                 = "listKeys"
  response_export_values = ["primaryKey", "secondaryKey"]

  depends_on = [azapi_resource.redis_database]
}

# -----------------------------------------------------------------------------
# Diagnostic Settings for Redis
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "redis" {
  name                       = "diag-redis"
  target_resource_id         = azapi_resource.redis.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_metric {
    category = "AllMetrics"
  }

  depends_on = [azapi_resource.redis]
}

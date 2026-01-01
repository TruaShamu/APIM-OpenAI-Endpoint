# =============================================================================
# LLM AI Gateway - Azure Redis Enterprise
# =============================================================================
# Provides semantic caching with vector search using RediSearch module.
# Azure Redis Enterprise supports RediSearch for similarity search.
# =============================================================================

# -----------------------------------------------------------------------------
# Azure Redis Enterprise Cluster
# -----------------------------------------------------------------------------

resource "azurerm_redis_enterprise_cluster" "main" {
  name                = "redis-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = var.redis_enterprise_sku
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.main]
}

# -----------------------------------------------------------------------------
# Azure Redis Enterprise Database with RediSearch
# -----------------------------------------------------------------------------

resource "azurerm_redis_enterprise_database" "main" {
  name              = "default"
  cluster_id        = azurerm_redis_enterprise_cluster.main.id
  client_protocol   = "Encrypted"
  clustering_policy = "EnterpriseCluster"
  eviction_policy   = "NoEviction"

  module {
    name = "RediSearch"
  }

  depends_on = [azurerm_redis_enterprise_cluster.main]
}

# -----------------------------------------------------------------------------
# Diagnostic Settings for Redis Enterprise
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "redis" {
  name                       = "diag-redis"
  target_resource_id         = azurerm_redis_enterprise_cluster.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_metric {
    category = "AllMetrics"
  }

  depends_on = [azurerm_redis_enterprise_cluster.main]
}

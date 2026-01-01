# =============================================================================
# LLM AI Gateway - Input Variables
# =============================================================================

# -----------------------------------------------------------------------------
# General Configuration
# -----------------------------------------------------------------------------

variable "subscription_id" {
  description = "Azure subscription ID for deployment"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-llm-gateway"
}

variable "location_primary" {
  description = "Primary Azure region for deployment"
  type        = string
  default     = "westus"
}

variable "location_secondary" {
  description = "Secondary Azure region for Azure OpenAI (load balancing)"
  type        = string
  default     = "westus2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    project    = "llm-gateway"
    managed_by = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Azure API Management Configuration
# -----------------------------------------------------------------------------

variable "apim_name" {
  description = "Name of the API Management instance"
  type        = string
  default     = "apim-llm-gateway"
}

variable "apim_sku_name" {
  description = "SKU for API Management (Developer, Basic, Standard, Premium)"
  type        = string
  default     = "Developer"
}

variable "apim_sku_capacity" {
  description = "Capacity units for API Management"
  type        = number
  default     = 1
}

variable "apim_publisher_name" {
  description = "Publisher name for API Management"
  type        = string
  default     = "LLM Gateway Admin"
}

variable "apim_publisher_email" {
  description = "Publisher email for API Management"
  type        = string
}

# -----------------------------------------------------------------------------
# Azure OpenAI Configuration
# -----------------------------------------------------------------------------

variable "openai_sku" {
  description = "SKU for Azure OpenAI service"
  type        = string
  default     = "S0"
}

variable "openai_deployments" {
  description = "List of model deployments for Azure OpenAI"
  type = list(object({
    name       = string
    model_name = string
    version    = string
    capacity   = number
  }))
  default = [
    {
      name       = "gpt-4o-mini"
      model_name = "gpt-4o-mini"
      version    = "2024-07-18"
      capacity   = 10
    },
    {
      name       = "gpt-image-1"
      model_name = "gpt-image-1"
      version    = "2025-04-15"
      capacity   = 5
    }
  ]
}

# -----------------------------------------------------------------------------
# Azure Managed Redis (Enterprise) Configuration
# -----------------------------------------------------------------------------

variable "redis_enterprise_sku" {
  description = "SKU for Azure Managed Redis Enterprise (Balanced_B0, Balanced_B1, etc.)"
  type        = string
  default     = "Balanced_B0"
}

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------

variable "rate_limit_calls" {
  description = "Number of API calls allowed per rate limit period"
  type        = number
  default     = 100
}

variable "rate_limit_period" {
  description = "Rate limit period in seconds"
  type        = number
  default     = 60
}

variable "token_limit_per_minute" {
  description = "Maximum tokens per minute per subscription"
  type        = number
  default     = 10000
}

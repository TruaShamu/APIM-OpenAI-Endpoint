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
  default     = "eastus"
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

variable "use_existing_apim" {
  description = "Whether to use an existing APIM instance instead of creating a new one"
  type        = bool
  default     = true
}

variable "existing_apim_name" {
  description = "Name of the existing APIM instance (required if use_existing_apim is true)"
  type        = string
  default     = "apim-raly"
}

variable "existing_apim_resource_group" {
  description = "Resource group of the existing APIM instance"
  type        = string
  default     = "rg-prod-core"
}

variable "apim_name" {
  description = "Name of the API Management instance (used if creating new)"
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
    }
  ]
}

# -----------------------------------------------------------------------------
# Azure Managed Redis Configuration
# -----------------------------------------------------------------------------

variable "redis_sku" {
  description = "SKU for Azure Managed Redis. Options: Balanced_B0, Balanced_B1, Balanced_B3, Balanced_B5, etc."
  type        = string
  default     = "Balanced_B0"

  validation {
    condition     = can(regex("^(Balanced_B[0-9]+|MemoryOptimized_M[0-9]+|ComputeOptimized_X[0-9]+|FlashOptimized_A[0-9]+)$", var.redis_sku))
    error_message = "SKU must be a valid Azure Managed Redis SKU: Balanced_B*, MemoryOptimized_M*, ComputeOptimized_X*, or FlashOptimized_A*."
  }
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

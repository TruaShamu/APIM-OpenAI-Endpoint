# =============================================================================
# LLM AI Gateway - Terraform Provider Configuration
# =============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
    api_management {
      purge_soft_delete_on_destroy = true
    }
  }

  subscription_id = var.subscription_id
}

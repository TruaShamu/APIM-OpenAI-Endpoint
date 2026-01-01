# Pipeline Deployment Guide

## Prerequisites

Before deploying, you need to set up the following:

### 1. Create an Azure Service Principal

Run this command in Azure CLI to create a service principal with Contributor access:

```bash
az ad sp create-for-rbac --name "sp-llm-gateway-deploy" \
  --role Contributor \
  --scopes /subscriptions/<YOUR_SUBSCRIPTION_ID> \
  --sdk-auth
```

This outputs JSON that looks like:
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  ...
}
```

### 2. Configure GitHub Secrets

Go to your repository → **Settings** → **Secrets and variables** → **Actions** → **Secrets**

Add these **Repository Secrets**:

| Secret Name | Value |
|-------------|-------|
| `AZURE_CREDENTIALS` | The entire JSON output from step 1 |
| `AZURE_CLIENT_ID` | The `clientId` from the JSON |
| `AZURE_CLIENT_SECRET` | The `clientSecret` from the JSON |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |
| `AZURE_TENANT_ID` | The `tenantId` from the JSON |
| `APIM_PUBLISHER_EMAIL` | Your email for APIM notifications |

### 3. Configure GitHub Variables (Optional)

Go to **Settings** → **Secrets and variables** → **Actions** → **Variables**

Add these **Repository Variables** (or use defaults):

| Variable Name | Default | Description |
|--------------|---------|-------------|
| `RESOURCE_GROUP_NAME` | `rg-llm-gateway` | Resource group name |
| `APIM_NAME` | `apim-llm-gateway` | APIM instance name |
| `LOCATION_PRIMARY` | `westus` | Primary Azure region |
| `LOCATION_SECONDARY` | `westus2` | Secondary Azure region |
| `ENVIRONMENT` | `dev` | Environment tag |
| `APIM_SKU` | `Developer` | APIM SKU |
| `REDIS_SKU` | `Balanced_B0` | Redis Enterprise SKU |

### 4. Set Up Terraform Backend (Recommended for Production)

For production, store Terraform state in Azure Storage:

```bash
# Create storage account for state
az group create --name rg-terraform-state --location westus
az storage account create --name tfstatellmgateway --resource-group rg-terraform-state --sku Standard_LRS
az storage container create --name tfstate --account-name tfstatellmgateway
```

Then add this backend configuration to `providers.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatellmgateway"
    container_name       = "tfstate"
    key                  = "llm-gateway.tfstate"
  }
}
```

---

## Deployment Workflow

### Automatic Deployment
- **Pull Request**: Runs `terraform plan` and comments results on the PR
- **Push to main**: Runs `terraform plan` then `terraform apply`

### Manual Deployment
1. Go to **Actions** → **Deploy LLM Gateway Infrastructure**
2. Click **Run workflow**
3. Select action:
   - `plan` - Preview changes only
   - `apply` - Deploy infrastructure
   - `destroy` - Tear down all resources

---

## Quick Start

1. **Fork/clone** this repository
2. **Create service principal** (step 1 above)
3. **Add GitHub secrets** (step 2 above)
4. **Push to main** or manually trigger the workflow

The pipeline will:
1. Initialize Terraform
2. Validate configuration
3. Plan changes
4. Apply changes (on main branch)
5. Output the APIM gateway URL

---

## Estimated Deployment Time

| Resource | Time |
|----------|------|
| API Management (Developer) | ~30-45 minutes |
| Azure OpenAI (x2) | ~5 minutes |
| Redis Enterprise | ~10-15 minutes |
| Other resources | ~2-5 minutes |

**Total: ~45-60 minutes** for first deployment

---

## Post-Deployment

After deployment, you'll need to:

1. **Create an APIM subscription** to get an API key
2. **Test the endpoint**:
   ```bash
   curl -X POST "https://<apim-name>.azure-api.net/openai/deployments/gpt-4o-mini/chat/completions?api-version=2024-02-01" \
     -H "api-key: <your-subscription-key>" \
     -H "Content-Type: application/json" \
     -d '{"messages":[{"role":"user","content":"Hello!"}]}'
   ```

---

## Cost Estimates (Monthly)

| Resource | SKU | Estimated Cost |
|----------|-----|----------------|
| API Management | Developer | ~$50 |
| Azure OpenAI | S0 | Pay-per-use (~$0.15/1M tokens for gpt-4o-mini) |
| Redis Enterprise | Balanced_B0 | ~$200 |
| Log Analytics | Pay-as-you-go | ~$5-20 |

**Total: ~$255-270/month** (varies by usage)

For cost savings in dev, consider:
- Using APIM Consumption tier (pay-per-call)
- Scaling down Redis after testing

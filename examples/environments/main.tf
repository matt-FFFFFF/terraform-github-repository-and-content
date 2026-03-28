terraform {
  required_version = "~> 1.11"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.8"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

variable "owner_is_organization" {
  description = "Whether the repository owner is a GitHub organization (true) or a personal user account (false)."
  type        = bool
  default     = true
}

variable "archive_on_destroy" {
  description = "Archive the repository instead of deleting on destroy."
  type        = bool
  default     = true
}

variable "resource_group_id" {
  description = "Azure resource group ID where managed identities will be created."
  type        = string
}

variable "location" {
  description = "Azure region for managed identities."
  type        = string
  default     = "uksouth"
}

variable "app_resource_group_id" {
  description = "Azure resource group ID to scope role assignments to."
  type        = string
}

resource "random_pet" "this" {}

# -----------------------------------------------------------------------------
# New repo with environments and Azure identities
# -----------------------------------------------------------------------------

module "repo" {
  source = "../../"

  name                  = random_pet.this.id
  description           = "Repo with managed environments and Azure identities"
  archive_on_destroy    = var.archive_on_destroy
  owner_is_organization = var.owner_is_organization

  environments = {
    stg = {
      environment = "staging"
      variables = {
        region = {
          name  = "REGION"
          value = "us-east-1"
        }
        debug = {
          name  = "DEBUG"
          value = "true"
        }
      }
      secrets = {
        api_key     = { name = "API_KEY" }
        db_password = { name = "DB_PASSWORD" }
      }
      # Staging environment with an Azure managed identity
      identity = {
        name      = "id-${random_pet.this.id}-staging"
        parent_id = var.resource_group_id
        location  = var.location
      }
      # Role assignments for the staging identity
      identity_role_assignments = {
        reader = {
          role_definition_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          scope              = var.app_resource_group_id
        }
      }
    }
    prod = {
      environment         = "production"
      wait_timer          = 30
      can_admins_bypass   = false
      prevent_self_review = true
      variables = {
        region = {
          name  = "REGION"
          value = "us-east-1"
        }
      }
      secrets = {
        api_key     = { name = "API_KEY" }
        db_password = { name = "DB_PASSWORD" }
        deploy_key  = { name = "DEPLOY_KEY" }
      }
      deployment_policy = {
        custom_branch_policies = true
      }
      branch_policies = ["releases/*", "main"]
      tag_policies    = ["v*"]
      # Production environment with an Azure managed identity
      identity = {
        name      = "id-${random_pet.this.id}-production"
        parent_id = var.resource_group_id
        location  = var.location
      }
      # Role assignments for the production identity
      identity_role_assignments = {
        contributor = {
          role_definition_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
          scope              = var.app_resource_group_id
        }
        storage_blob_reader = {
          role_definition_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
          scope              = var.app_resource_group_id
          condition          = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'deployments'"
          condition_version  = "2.0"
        }
      }
    }
  }
}

output "full_name" {
  value = module.repo.full_name
}

output "html_url" {
  value = module.repo.html_url
}

output "environments" {
  value = module.repo.environments
}

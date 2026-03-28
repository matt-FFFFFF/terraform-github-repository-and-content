terraform {
  required_version = "~> 1.11"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "github" {
  # Configure via GITHUB_TOKEN env var and optionally GITHUB_OWNER.
}

variable "owner_is_organization" {
  description = "Whether the repository owner is a GitHub organization (true) or a personal user account (false)."
  type        = bool
  default     = true
}

resource "random_pet" "this" {}

# -----------------------------------------------------------------------------
# Customize OIDC subject claims for GitHub Actions
# -----------------------------------------------------------------------------

module "repo" {
  source = "../../"

  name                  = random_pet.this.id
  description           = "Repository with custom OIDC subject claims"
  owner_is_organization = var.owner_is_organization

  actions_oidc_subject_claims = {
    use_default        = false
    include_claim_keys = ["repository_owner_id", "repository_id", "environment"]
  }
}

output "full_name" {
  value = module.repo.full_name
}

output "html_url" {
  value = module.repo.html_url
}

output "default_branch" {
  value = module.repo.default_branch
}

output "actions_oidc_subject_claim_values" {
  value = module.repo.actions_oidc_subject_claim_values
}

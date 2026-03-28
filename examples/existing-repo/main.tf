terraform {
  required_version = "~> 1.11"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
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

# -----------------------------------------------------------------------------
# Add content to an existing repo (no repo creation)
# -----------------------------------------------------------------------------

module "repo" {
  source = "../../"

  create_repository           = false
  name                        = "existing-repo-name"
  owner_is_organization       = var.owner_is_organization
  actions_oidc_subject_claims = null

  files = {
    ".github/CODEOWNERS" = "* @my-org/platform-team\n"
  }
}

output "default_branch" {
  value = module.repo.default_branch
}

output "files" {
  value = module.repo.files
}

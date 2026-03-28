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

variable "archive_on_destroy" {
  description = "Archive the repository instead of deleting on destroy."
  type        = bool
  default     = true
}

resource "random_pet" "this" {}

# -----------------------------------------------------------------------------
# Teams - create teams to grant access to the repository
# -----------------------------------------------------------------------------

resource "github_team" "developers" {
  name        = "developers-${random_pet.this.id}"
  description = "Development team"
  privacy     = "closed"
}

resource "github_team" "platform" {
  name        = "platform-${random_pet.this.id}"
  description = "Platform team"
  privacy     = "closed"
}

# -----------------------------------------------------------------------------
# New repo with team permissions
# -----------------------------------------------------------------------------

module "repo" {
  source = "../../"

  name                  = random_pet.this.id
  description           = "Repo with managed permissions"
  archive_on_destroy    = var.archive_on_destroy
  owner_is_organization = var.owner_is_organization

  # collaborators = {
  #   alice = {
  #     username   = "alice"
  #     permission = "push"
  #   }
  #   bob = {
  #     username   = "bob"
  #     permission = "admin"
  #   }
  # }

  teams = {
    developers = {
      team_id    = github_team.developers.slug
      permission = "push"
    }
    platform = {
      team_id    = github_team.platform.slug
      permission = "maintain"
    }
  }
}

output "full_name" {
  value = module.repo.full_name
}

output "html_url" {
  value = module.repo.html_url
}

output "teams" {
  value = module.repo.teams
}

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
# New repo with a full directory tree loaded from disk
#
# fileset() finds every file under content/, then file() reads each one.
# The result is a map(string) keyed by the repo-relative path.
# -----------------------------------------------------------------------------

module "repo" {
  source = "../../"

  name                  = random_pet.this.id
  description           = "Application managed by Terraform"
  visibility            = "private"
  archive_on_destroy    = var.archive_on_destroy
  owner_is_organization = var.owner_is_organization

  # Load every file under the local content/ directory into the repo.
  files_dir = "${path.module}/content"
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

output "files" {
  value = module.repo.files
}

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
# Create from a template repository
# -----------------------------------------------------------------------------

module "repo" {
  source = "../../"

  name                  = random_pet.this.id
  description           = "Bootstrapped from our org template"
  archive_on_destroy    = var.archive_on_destroy
  owner_is_organization = var.owner_is_organization

  template = {
    owner      = "my-org"
    repository = "microservice-template"
  }

  files = {
    "terraform.tfvars" = <<-EOT
      service_name = "${random_pet.this.id}"
      environment  = "dev"
    EOT
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

output "files" {
  value = module.repo.files
}

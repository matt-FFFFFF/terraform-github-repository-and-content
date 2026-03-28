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
# New repo with inline content
# -----------------------------------------------------------------------------

module "repo" {
  source = "../../"

  name                  = random_pet.this.id
  description           = "Service repo"
  default_branch        = "main"
  archive_on_destroy    = var.archive_on_destroy
  owner_is_organization = var.owner_is_organization

  files = {
    "README.md"   = "# ${random_pet.this.id}\n\nManaged by Terraform.\n"
    "src/main.py" = <<-EOT
      def handler(event, context):
          return {"statusCode": 200}
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

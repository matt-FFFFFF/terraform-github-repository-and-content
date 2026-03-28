terraform {
  required_version = ">= 1.5"

  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0"
    }
  }
}

provider "github" {
  # Configure via GITHUB_TOKEN env var and optionally GITHUB_OWNER.
}

# -----------------------------------------------------------------------------
# Example 1 – New repo with a full directory tree loaded from disk
#
# fileset() finds every file under content/, then file() reads each one.
# The result is a map(string) keyed by the repo-relative path.
# -----------------------------------------------------------------------------

module "repo_from_directory" {
  source = "../../"

  name        = "my-app"
  description = "Application managed by Terraform"
  visibility  = "private"

  # Load every file under the local content/ directory into the repo.
  # fileset returns paths relative to the first argument, so the keys
  # end up as repo-relative paths like "src/main.py", "README.md", etc.
  files = {
    for path in fileset("${path.module}/content", "**") :
    path => file("${path.module}/content/${path}")
  }
}

# -----------------------------------------------------------------------------
# Example 2 – New repo with inline content
# -----------------------------------------------------------------------------

module "repo_inline" {
  source = "../../"

  name           = "my-service"
  description    = "Service repo"
  default_branch = "main"

  files = {
    "README.md"   = "# my-service\n\nManaged by Terraform.\n"
    "src/main.py" = <<-EOT
      def handler(event, context):
          return {"statusCode": 200}
    EOT
  }
}

# -----------------------------------------------------------------------------
# Example 3 – Push files to a feature branch
# -----------------------------------------------------------------------------

module "repo_feature_branch" {
  source = "../../"

  name   = "my-config"
  branch = "config-update"

  files = {
    "config.yaml" = <<-EOT
      setting: true
      level: 5
    EOT
  }
}

# -----------------------------------------------------------------------------
# Example 4 – Add content to an existing repo (no repo creation)
# -----------------------------------------------------------------------------

module "existing_repo_content" {
  source = "../../"

  create_repository = false
  name              = "existing-repo-name"

  files = {
    ".github/CODEOWNERS" = "* @my-org/platform-team\n"
  }
}

# -----------------------------------------------------------------------------
# Example 5 – Create from a template repository
# -----------------------------------------------------------------------------

module "repo_from_template" {
  source = "../../"

  name        = "new-microservice"
  description = "Bootstrapped from our org template"

  template = {
    owner      = "my-org"
    repository = "microservice-template"
  }

  files = {
    "terraform.tfvars" = <<-EOT
      service_name = "new-microservice"
      environment  = "dev"
    EOT
  }
}

# -----------------------------------------------------------------------------
# Example 6 – Customize OIDC subject claims for GitHub Actions
# -----------------------------------------------------------------------------

module "repo_with_oidc_claims" {
  source = "../../"

  name        = "my-oidc-repo"
  description = "Repository with custom OIDC subject claims"

  actions_oidc_subject_claims = {
    use_default        = false
    include_claim_keys = ["repository_owner_id", "repository_id", "environment"]
  }
}

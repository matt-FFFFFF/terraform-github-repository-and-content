# -----------------------------------------------------------------------------
# Unit tests for modules/environment
#
# These tests use provider mocking so no real GitHub resources are created.
# -----------------------------------------------------------------------------

mock_provider "github" {
  mock_resource "github_repository_environment" {
    defaults = {}
  }

  mock_resource "github_actions_environment_variable" {
    defaults = {
      created_at    = "2024-01-01T00:00:00Z"
      updated_at    = "2024-01-01T00:00:00Z"
      repository_id = 123456
    }
  }

  mock_resource "github_actions_environment_secret" {
    defaults = {
      created_at        = "2024-01-01T00:00:00Z"
      updated_at        = "2024-01-01T00:00:00Z"
      remote_updated_at = "2024-01-01T00:00:00Z"
      repository_id     = 123456
    }
  }

  mock_resource "github_repository_environment_deployment_policy" {
    defaults = {}
  }
}

# File-level variables applied to all run blocks unless overridden.
variables {
  repository  = "test-repo"
  environment = "test-env"
}

# =============================================================================
# Basic environment creation
# =============================================================================

run "basic_environment" {
  command = apply

  assert {
    condition     = github_repository_environment.this.repository == "test-repo"
    error_message = "Repository should match the variable."
  }

  assert {
    condition     = github_repository_environment.this.environment == "test-env"
    error_message = "Environment name should match the variable."
  }

  assert {
    condition     = github_repository_environment.this.can_admins_bypass == true
    error_message = "can_admins_bypass should default to true."
  }

  assert {
    condition     = github_repository_environment.this.prevent_self_review == false
    error_message = "prevent_self_review should default to false."
  }

  assert {
    condition     = length(github_actions_environment_variable.this) == 0
    error_message = "No variables should be created by default."
  }

  assert {
    condition     = length(github_actions_environment_secret.this) == 0
    error_message = "No secrets should be created by default."
  }

  assert {
    condition     = length(github_repository_environment_deployment_policy.this) == 0
    error_message = "No deployment policies should be created by default."
  }
}

# =============================================================================
# Custom environment settings
# =============================================================================

run "custom_environment_settings" {
  command = apply

  variables {
    repository          = "test-repo"
    environment         = "production"
    wait_timer          = 30
    can_admins_bypass   = false
    prevent_self_review = true
  }

  assert {
    condition     = github_repository_environment.this.environment == "production"
    error_message = "Environment name should be 'production'."
  }

  assert {
    condition     = github_repository_environment.this.wait_timer == 30
    error_message = "Wait timer should be 30."
  }

  assert {
    condition     = github_repository_environment.this.can_admins_bypass == false
    error_message = "can_admins_bypass should be false when explicitly set."
  }

  assert {
    condition     = github_repository_environment.this.prevent_self_review == true
    error_message = "prevent_self_review should be true when explicitly set."
  }
}

# =============================================================================
# Environment variables
# =============================================================================

run "environment_variables" {
  command = apply

  variables {
    repository  = "test-repo"
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
  }

  assert {
    condition     = length(github_actions_environment_variable.this) == 2
    error_message = "Should create 2 environment variables."
  }

  assert {
    condition     = github_actions_environment_variable.this["region"].variable_name == "REGION"
    error_message = "Variable name should be REGION."
  }

  assert {
    condition     = github_actions_environment_variable.this["region"].value == "us-east-1"
    error_message = "Variable value should be us-east-1."
  }

  assert {
    condition     = github_actions_environment_variable.this["debug"].variable_name == "DEBUG"
    error_message = "Variable name should be DEBUG."
  }

  assert {
    condition     = github_actions_environment_variable.this["debug"].value == "true"
    error_message = "Variable value should be true."
  }
}

# =============================================================================
# Environment secrets (names only)
# =============================================================================

run "environment_secrets" {
  command = apply

  variables {
    repository  = "test-repo"
    environment = "staging"
    secrets = {
      api_key     = { name = "API_KEY" }
      db_password = { name = "DB_PASSWORD" }
    }
  }

  assert {
    condition     = length(github_actions_environment_secret.this) == 2
    error_message = "Should create 2 environment secrets."
  }

  assert {
    condition     = output.secrets["api_key"].secret_name == "API_KEY"
    error_message = "Secret name should be API_KEY."
  }

  assert {
    condition     = output.secrets["db_password"].secret_name == "DB_PASSWORD"
    error_message = "Secret name should be DB_PASSWORD."
  }
}

# =============================================================================
# Custom deployment policies (branches and tags)
# =============================================================================

run "custom_branch_deployment_policies" {
  command = apply

  variables {
    repository  = "test-repo"
    environment = "production"
    deployment_policy = {
      custom_branch_policies = true
    }
    branch_policies = ["releases/*", "main"]
  }

  assert {
    condition     = length(github_repository_environment_deployment_policy.this) == 2
    error_message = "Should create 2 branch deployment policies."
  }

  assert {
    condition     = github_repository_environment_deployment_policy.this["branch:releases/*"].branch_pattern == "releases/*"
    error_message = "Branch pattern should be releases/*."
  }

  assert {
    condition     = github_repository_environment_deployment_policy.this["branch:main"].branch_pattern == "main"
    error_message = "Branch pattern should be main."
  }
}

run "custom_tag_deployment_policies" {
  command = apply

  variables {
    repository  = "test-repo"
    environment = "production"
    deployment_policy = {
      custom_branch_policies = true
    }
    tag_policies = ["v*"]
  }

  assert {
    condition     = length(github_repository_environment_deployment_policy.this) == 1
    error_message = "Should create 1 tag deployment policy."
  }

  assert {
    condition     = github_repository_environment_deployment_policy.this["tag:v*"].tag_pattern == "v*"
    error_message = "Tag pattern should be v*."
  }
}

run "mixed_branch_and_tag_policies" {
  command = apply

  variables {
    repository  = "test-repo"
    environment = "production"
    deployment_policy = {
      custom_branch_policies = true
    }
    branch_policies = ["releases/*", "main"]
    tag_policies    = ["v*"]
  }

  assert {
    condition     = length(github_repository_environment_deployment_policy.this) == 3
    error_message = "Should create 3 deployment policies (2 branch + 1 tag)."
  }
}

run "protected_branches_deployment_policy" {
  command = apply

  variables {
    repository  = "test-repo"
    environment = "production"
    deployment_policy = {
      protected_branches = true
    }
  }

  assert {
    condition     = length(github_repository_environment_deployment_policy.this) == 0
    error_message = "No custom deployment policies should be created with protected_branches only."
  }
}

# =============================================================================
# Outputs
# =============================================================================

run "outputs_populated" {
  command = apply

  variables {
    repository  = "test-repo"
    environment = "staging"
    variables = {
      region = {
        name  = "REGION"
        value = "us-east-1"
      }
    }
    secrets = {
      api_key = { name = "API_KEY" }
    }
    deployment_policy = {
      custom_branch_policies = true
    }
    branch_policies = ["main"]
  }

  assert {
    condition     = output.environment.environment == "staging"
    error_message = "Environment output should expose the environment resource."
  }

  assert {
    condition     = length(output.variables) == 1
    error_message = "Variables output should contain 1 entry."
  }

  assert {
    condition     = length(output.secrets) == 1
    error_message = "Secrets output should contain 1 entry."
  }

  assert {
    condition     = length(output.deployment_policies) == 1
    error_message = "Deployment policies output should contain 1 entry."
  }
}

# =============================================================================
# Validation
# =============================================================================

run "branch_policies_without_custom_rejected" {
  command = plan

  variables {
    repository      = "test-repo"
    environment     = "bad-env"
    branch_policies = ["main"]
  }

  expect_failures = [
    var.branch_policies,
  ]
}

run "tag_policies_without_custom_rejected" {
  command = plan

  variables {
    repository   = "test-repo"
    environment  = "bad-env"
    tag_policies = ["v*"]
  }

  expect_failures = [
    var.tag_policies,
  ]
}

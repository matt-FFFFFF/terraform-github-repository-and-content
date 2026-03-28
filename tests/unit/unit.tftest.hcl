# -----------------------------------------------------------------------------
# Unit tests for terraform-github-repository-and-content
#
# These tests use provider mocking so no real GitHub resources are created.
# All providers declared in terraform.tf must be mocked.
# -----------------------------------------------------------------------------

mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      name           = "test-repo"
      full_name      = "test-org/test-repo"
      html_url       = "https://github.com/test-org/test-repo"
      ssh_clone_url  = "git@github.com:test-org/test-repo.git"
      http_clone_url = "https://github.com/test-org/test-repo.git"
      repo_id        = 123456
      visibility     = "private"
    }
  }

  mock_resource "github_repository_file" {
    defaults = {
      commit_sha = "abc123def456"
    }
  }

  mock_resource "github_repository_collaborator" {
    defaults = {
      invitation_id = "inv-123"
    }
  }

  mock_resource "github_team_repository" {
    defaults = {
      etag = "etag-123"
    }
  }

  mock_data "github_repository" {
    defaults = {
      full_name  = "test-org/test-repo"
      repo_id    = 123456
      visibility = "private"
    }
  }

  mock_data "github_organization" {
    defaults = {
      login = "test-org"
      id    = "org-123"
    }
  }

  mock_data "github_user" {
    defaults = {
      login = "test-user"
      id    = "user-456"
    }
  }
}

# File-level variables applied to all run blocks unless overridden.
variables {
  name = "test-repo"
}

# =============================================================================
# Repository creation defaults
# =============================================================================

run "default_repository_creation" {
  command = apply

  assert {
    condition     = length(github_repository.this) == 1
    error_message = "Repository should be created when create_repository is true (default)."
  }

  assert {
    condition     = length(github_branch_default.this) == 1
    error_message = "Default branch should be configured when creating a repository."
  }

  assert {
    condition     = github_repository.this[0].name == "test-repo"
    error_message = "Repository name should match the name variable."
  }

  assert {
    condition     = github_repository.this[0].visibility == "private"
    error_message = "Repository visibility should default to private."
  }

  assert {
    condition     = github_repository.this[0].auto_init == true
    error_message = "auto_init should default to true."
  }

  assert {
    condition     = github_repository.this[0].archive_on_destroy == true
    error_message = "archive_on_destroy should default to true."
  }

  assert {
    condition     = github_repository.this[0].has_issues == true
    error_message = "has_issues should default to true."
  }

  assert {
    condition     = github_repository.this[0].has_projects == false
    error_message = "has_projects should default to false."
  }

  assert {
    condition     = github_repository.this[0].has_wiki == false
    error_message = "has_wiki should default to false."
  }

  assert {
    condition     = github_branch_default.this[0].branch == "main"
    error_message = "Default branch should be 'main'."
  }

  assert {
    condition     = output.default_branch == "main"
    error_message = "Default branch output should be 'main'."
  }
}

# =============================================================================
# Variable validation
# =============================================================================

run "invalid_visibility_rejected" {
  command = plan

  variables {
    name       = "test-repo"
    visibility = "invalid"
  }

  expect_failures = [
    var.visibility,
  ]
}

# =============================================================================
# Custom repository settings
# =============================================================================

run "custom_repository_settings" {
  command = apply

  variables {
    name         = "custom-repo"
    description  = "A custom repository"
    visibility   = "public"
    has_issues   = false
    has_projects = true
    has_wiki     = true
    auto_init    = false
  }

  assert {
    condition     = github_repository.this[0].description == "A custom repository"
    error_message = "Repository description should match the variable."
  }

  assert {
    condition     = github_repository.this[0].visibility == "public"
    error_message = "Repository visibility should be public."
  }

  assert {
    condition     = github_repository.this[0].has_issues == false
    error_message = "has_issues should be false when explicitly set."
  }

  assert {
    condition     = github_repository.this[0].has_projects == true
    error_message = "has_projects should be true when explicitly set."
  }

  assert {
    condition     = github_repository.this[0].has_wiki == true
    error_message = "has_wiki should be true when explicitly set."
  }

  assert {
    condition     = github_repository.this[0].auto_init == false
    error_message = "auto_init should be false when explicitly set."
  }
}

# =============================================================================
# File management
# =============================================================================

run "file_management" {
  command = apply

  variables {
    name = "test-repo"
    files = {
      "README.md"   = "# Hello"
      "src/main.py" = "print('hello')"
    }
  }

  assert {
    condition     = length(github_repository_file.this) == 2
    error_message = "Should create 2 repository files."
  }

  assert {
    condition     = length(output.files) == 2
    error_message = "Files output should contain 2 entries."
  }

  assert {
    condition     = github_repository_file.this["README.md"].file == "README.md"
    error_message = "README.md file path should be set correctly."
  }

  assert {
    condition     = github_repository_file.this["src/main.py"].file == "src/main.py"
    error_message = "src/main.py file path should be set correctly."
  }

  assert {
    condition     = github_repository_file.this["README.md"].content == "# Hello"
    error_message = "README.md content should match input."
  }

  assert {
    condition     = github_repository_file.this["README.md"].commit_author == "Terraform"
    error_message = "Commit author should default to 'Terraform'."
  }

  assert {
    condition     = github_repository_file.this["README.md"].commit_email == "terraform@localhost"
    error_message = "Commit email should default to 'terraform@localhost'."
  }

  assert {
    condition     = github_repository_file.this["README.md"].commit_message == "terraform: update README.md"
    error_message = "Commit message should use the default prefix."
  }

  assert {
    condition     = github_repository_file.this["README.md"].overwrite_on_create == true
    error_message = "overwrite_on_create should be true."
  }

  assert {
    condition     = github_repository_file.this["README.md"].branch == "main"
    error_message = "Files should be committed to the default branch when no branch is specified."
  }
}

# =============================================================================
# Custom commit settings
# =============================================================================

run "custom_commit_settings" {
  command = apply

  variables {
    name                  = "test-repo"
    commit_author         = "CI Bot"
    commit_email          = "ci@example.com"
    commit_message_prefix = "ci: "
    files = {
      "test.txt" = "content"
    }
  }

  assert {
    condition     = github_repository_file.this["test.txt"].commit_author == "CI Bot"
    error_message = "Commit author should match the custom value."
  }

  assert {
    condition     = github_repository_file.this["test.txt"].commit_email == "ci@example.com"
    error_message = "Commit email should match the custom value."
  }

  assert {
    condition     = github_repository_file.this["test.txt"].commit_message == "ci: update test.txt"
    error_message = "Commit message should use the custom prefix."
  }
}

# =============================================================================
# Branch management
# =============================================================================

run "non_default_branch_created" {
  command = apply

  variables {
    name   = "test-repo"
    branch = "feature-branch"
    files = {
      "config.yml" = "key: value"
    }
  }

  assert {
    condition     = length(github_branch.target) == 1
    error_message = "Branch resource should be created when targeting a non-default branch."
  }

  assert {
    condition     = github_branch.target[0].branch == "feature-branch"
    error_message = "Branch name should match the branch variable."
  }

  assert {
    condition     = github_branch.target[0].source_branch == "main"
    error_message = "Source branch should be the default branch."
  }

  assert {
    condition     = github_repository_file.this["config.yml"].branch == "feature-branch"
    error_message = "Files should be committed to the specified branch."
  }
}

run "branch_same_as_default_no_extra_branch" {
  command = apply

  variables {
    name   = "test-repo"
    branch = "main"
  }

  assert {
    condition     = length(github_branch.target) == 0
    error_message = "Branch resource should not be created when branch equals the default branch."
  }
}

run "null_branch_uses_default" {
  command = apply

  variables {
    name   = "test-repo"
    branch = null
    files = {
      "test.txt" = "content"
    }
  }

  assert {
    condition     = length(github_branch.target) == 0
    error_message = "Branch resource should not be created when branch is null."
  }

  assert {
    condition     = github_repository_file.this["test.txt"].branch == "main"
    error_message = "Files should be committed to the default branch when branch is null."
  }
}

run "custom_default_branch" {
  command = apply

  variables {
    name           = "test-repo"
    default_branch = "develop"
  }

  assert {
    condition     = github_branch_default.this[0].branch == "develop"
    error_message = "Default branch should be set to the custom value."
  }

  assert {
    condition     = output.default_branch == "develop"
    error_message = "Default branch output should reflect the custom value."
  }
}

# =============================================================================
# Template repository
# =============================================================================

run "template_repository" {
  command = apply

  variables {
    name = "test-repo"
    template = {
      owner      = "my-org"
      repository = "template-repo"
    }
  }

  assert {
    condition     = length(github_repository.this) == 1
    error_message = "Repository should be created when using a template."
  }
}

# =============================================================================
# OIDC subject claim management
# =============================================================================

run "oidc_claims_disabled" {
  command = apply

  variables {
    name                        = "test-repo"
    actions_oidc_subject_claims = null
  }

  assert {
    condition     = length(github_actions_repository_oidc_subject_claim_customization_template.this) == 0
    error_message = "OIDC template should not be created when actions_oidc_subject_claims is null."
  }

  assert {
    condition     = length(data.github_organization.this) == 0
    error_message = "Organization data source should not be fetched when OIDC claims are disabled."
  }

  assert {
    condition     = length(keys(output.actions_oidc_subject_claim_values)) == 0
    error_message = "OIDC subject claim values should be empty when not managed."
  }
}

run "oidc_claims_default_settings" {
  command = apply

  variables {
    name = "test-repo"
  }

  assert {
    condition     = length(github_actions_repository_oidc_subject_claim_customization_template.this) == 1
    error_message = "OIDC template should be created with default settings."
  }

  assert {
    condition     = github_actions_repository_oidc_subject_claim_customization_template.this[0].use_default == false
    error_message = "OIDC use_default should be false by default."
  }

  assert {
    condition     = length(github_actions_repository_oidc_subject_claim_customization_template.this[0].include_claim_keys) == 3
    error_message = "OIDC should include 3 default claim keys (repository_owner_id, repository_id, environment)."
  }

  assert {
    condition     = length(data.github_organization.this) == 1
    error_message = "Organization data source should be fetched when OIDC claims are configured."
  }
}

run "oidc_claims_custom_settings" {
  command = apply

  variables {
    name = "test-repo"
    actions_oidc_subject_claims = {
      use_default        = true
      include_claim_keys = ["repository", "repository_owner"]
    }
  }

  assert {
    condition     = github_actions_repository_oidc_subject_claim_customization_template.this[0].use_default == true
    error_message = "OIDC use_default should be true when explicitly set."
  }

  assert {
    condition     = length(github_actions_repository_oidc_subject_claim_customization_template.this[0].include_claim_keys) == 2
    error_message = "OIDC should include 2 custom claim keys."
  }
}

# =============================================================================
# Skip repository creation (manage existing repo)
# =============================================================================

run "skip_repository_creation" {
  command = apply

  variables {
    name                        = "existing-repo"
    create_repository           = false
    actions_oidc_subject_claims = null
  }

  assert {
    condition     = length(github_repository.this) == 0
    error_message = "Repository resource should not be created when create_repository is false."
  }

  assert {
    condition     = length(github_branch_default.this) == 0
    error_message = "Default branch resource should not be managed when create_repository is false."
  }

  assert {
    condition     = output.repository == null
    error_message = "Repository output should be null when not creating."
  }

  assert {
    condition     = output.full_name == null
    error_message = "Full name output should be null when not creating."
  }

  assert {
    condition     = output.html_url == null
    error_message = "HTML URL output should be null when not creating."
  }

  assert {
    condition     = output.ssh_clone_url == null
    error_message = "SSH clone URL output should be null when not creating."
  }

  assert {
    condition     = output.http_clone_url == null
    error_message = "HTTP clone URL output should be null when not creating."
  }
}

run "existing_repo_with_oidc" {
  command = apply

  variables {
    name              = "existing-repo"
    create_repository = false
  }

  assert {
    condition     = length(data.github_repository.this) == 1
    error_message = "Data source should look up the existing repository for OIDC resolution."
  }

  assert {
    condition     = length(github_actions_repository_oidc_subject_claim_customization_template.this) == 1
    error_message = "OIDC claims should be managed for existing repositories."
  }

  assert {
    condition     = length(data.github_organization.this) == 1
    error_message = "Organization data source should be fetched for existing repo OIDC."
  }
}

run "existing_repo_with_files" {
  command = apply

  variables {
    name                        = "existing-repo"
    create_repository           = false
    actions_oidc_subject_claims = null
    files = {
      "docs/guide.md" = "# Guide"
    }
  }

  assert {
    condition     = length(github_repository_file.this) == 1
    error_message = "Files should be committed to existing repository."
  }

  assert {
    condition     = github_repository_file.this["docs/guide.md"].content == "# Guide"
    error_message = "File content should match input for existing repository."
  }
}

# =============================================================================
# Edge cases
# =============================================================================

run "no_files_empty_output" {
  command = apply

  variables {
    name  = "test-repo"
    files = {}
  }

  assert {
    condition     = length(output.files) == 0
    error_message = "Files output should be empty when no files are specified."
  }
}

run "outputs_populated_on_creation" {
  command = apply

  variables {
    name = "test-repo"
  }

  assert {
    condition     = output.repository != null
    error_message = "Repository output should not be null when creating."
  }

  assert {
    condition     = output.full_name != null
    error_message = "Full name output should not be null when creating."
  }

  assert {
    condition     = output.html_url != null
    error_message = "HTML URL output should not be null when creating."
  }

  assert {
    condition     = output.ssh_clone_url != null
    error_message = "SSH clone URL output should not be null when creating."
  }

  assert {
    condition     = output.http_clone_url != null
    error_message = "HTTP clone URL output should not be null when creating."
  }
}

# =============================================================================
# Personal account (owner_is_organization = false)
# =============================================================================

run "personal_account_with_oidc" {
  command = apply

  variables {
    name                  = "test-repo"
    owner_is_organization = false
  }

  assert {
    condition     = length(data.github_organization.this) == 0
    error_message = "Organization data source should not be fetched for personal accounts."
  }

  assert {
    condition     = length(data.github_user.this) == 1
    error_message = "User data source should be fetched for personal accounts with OIDC."
  }

  assert {
    condition     = length(github_actions_repository_oidc_subject_claim_customization_template.this) == 1
    error_message = "OIDC template should still be created for personal accounts."
  }
}

run "personal_account_oidc_disabled" {
  command = apply

  variables {
    name                        = "test-repo"
    owner_is_organization       = false
    actions_oidc_subject_claims = null
  }

  assert {
    condition     = length(data.github_organization.this) == 0
    error_message = "Organization data source should not be fetched when OIDC is disabled."
  }

  assert {
    condition     = length(data.github_user.this) == 0
    error_message = "User data source should not be fetched when OIDC is disabled."
  }
}

run "personal_account_existing_repo_with_oidc" {
  command = apply

  variables {
    name                  = "existing-repo"
    create_repository     = false
    owner_is_organization = false
  }

  assert {
    condition     = length(data.github_repository.this) == 1
    error_message = "Data source should look up the existing repository for OIDC resolution."
  }

  assert {
    condition     = length(data.github_organization.this) == 0
    error_message = "Organization data source should not be fetched for personal accounts."
  }

  assert {
    condition     = length(data.github_user.this) == 1
    error_message = "User data source should be fetched for personal account existing repo with OIDC."
  }

  assert {
    condition     = length(github_actions_repository_oidc_subject_claim_customization_template.this) == 1
    error_message = "OIDC claims should be managed for existing repos on personal accounts."
  }
}

# =============================================================================
# Repository permissions - collaborators
# =============================================================================

run "default_no_collaborators" {
  command = apply

  variables {
    name = "test-repo"
  }

  assert {
    condition     = length(github_repository_collaborator.this) == 0
    error_message = "No collaborators should be created when collaborators variable is empty (default)."
  }

  assert {
    condition     = length(output.collaborators) == 0
    error_message = "Collaborators output should be empty by default."
  }
}

run "default_no_teams" {
  command = apply

  variables {
    name = "test-repo"
  }

  assert {
    condition     = length(github_team_repository.this) == 0
    error_message = "No team repositories should be created when teams variable is empty (default)."
  }

  assert {
    condition     = length(output.teams) == 0
    error_message = "Teams output should be empty by default."
  }
}

run "collaborators_with_permissions" {
  command = apply

  variables {
    name = "test-repo"
    collaborators = {
      alice = {
        username   = "alice"
        permission = "push"
      }
      bob = {
        username   = "bob"
        permission = "admin"
      }
    }
  }

  assert {
    condition     = length(github_repository_collaborator.this) == 2
    error_message = "Should create 2 collaborator resources."
  }

  assert {
    condition     = github_repository_collaborator.this["alice"].username == "alice"
    error_message = "Alice's username should be set correctly."
  }

  assert {
    condition     = github_repository_collaborator.this["alice"].permission == "push"
    error_message = "Alice's permission should be push."
  }

  assert {
    condition     = github_repository_collaborator.this["bob"].username == "bob"
    error_message = "Bob's username should be set correctly."
  }

  assert {
    condition     = github_repository_collaborator.this["bob"].permission == "admin"
    error_message = "Bob's permission should be admin."
  }

  assert {
    condition     = github_repository_collaborator.this["alice"].repository == "test-repo"
    error_message = "Collaborator repository should match the repo name."
  }

  assert {
    condition     = output.collaborators["alice"].username == "alice"
    error_message = "Collaborators output should contain alice's username."
  }

  assert {
    condition     = output.collaborators["alice"].permission == "push"
    error_message = "Collaborators output should contain alice's permission."
  }

  assert {
    condition     = output.collaborators["bob"].permission == "admin"
    error_message = "Collaborators output should contain bob's permission."
  }
}

run "collaborator_default_permission" {
  command = apply

  variables {
    name = "test-repo"
    collaborators = {
      charlie = {
        username = "charlie"
      }
    }
  }

  assert {
    condition     = github_repository_collaborator.this["charlie"].permission == "push"
    error_message = "Default collaborator permission should be push."
  }
}

run "teams_with_permissions" {
  command = apply

  variables {
    name = "test-repo"
    teams = {
      devs = {
        team_id    = "developers"
        permission = "push"
      }
      admins = {
        team_id    = "platform-admins"
        permission = "admin"
      }
    }
  }

  assert {
    condition     = length(github_team_repository.this) == 2
    error_message = "Should create 2 team repository resources."
  }

  assert {
    condition     = github_team_repository.this["devs"].team_id == "developers"
    error_message = "Devs team_id should be set correctly."
  }

  assert {
    condition     = github_team_repository.this["devs"].permission == "push"
    error_message = "Devs permission should be push."
  }

  assert {
    condition     = github_team_repository.this["admins"].team_id == "platform-admins"
    error_message = "Admins team_id should be set correctly."
  }

  assert {
    condition     = github_team_repository.this["admins"].permission == "admin"
    error_message = "Admins permission should be admin."
  }

  assert {
    condition     = github_team_repository.this["devs"].repository == "test-repo"
    error_message = "Team repository should match the repo name."
  }

  assert {
    condition     = output.teams["devs"].team_id == "developers"
    error_message = "Teams output should contain devs team_id."
  }

  assert {
    condition     = output.teams["devs"].permission == "push"
    error_message = "Teams output should contain devs permission."
  }

  assert {
    condition     = output.teams["admins"].permission == "admin"
    error_message = "Teams output should contain admins permission."
  }
}

run "team_default_permission" {
  command = apply

  variables {
    name = "test-repo"
    teams = {
      readers = {
        team_id = "read-team"
      }
    }
  }

  assert {
    condition     = github_team_repository.this["readers"].permission == "push"
    error_message = "Default team permission should be push."
  }
}

run "collaborators_on_existing_repo" {
  command = apply

  variables {
    name                        = "existing-repo"
    create_repository           = false
    actions_oidc_subject_claims = null
    collaborators = {
      deploy_bot = {
        username   = "deploy-bot"
        permission = "maintain"
      }
    }
    teams = {
      ops = {
        team_id    = "operations"
        permission = "triage"
      }
    }
  }

  assert {
    condition     = length(github_repository_collaborator.this) == 1
    error_message = "Collaborators should be managed on existing repositories."
  }

  assert {
    condition     = github_repository_collaborator.this["deploy_bot"].username == "deploy-bot"
    error_message = "Collaborator username should be set on existing repo."
  }

  assert {
    condition     = github_repository_collaborator.this["deploy_bot"].permission == "maintain"
    error_message = "Collaborator permission should be maintain on existing repo."
  }

  assert {
    condition     = length(github_team_repository.this) == 1
    error_message = "Teams should be managed on existing repositories."
  }

  assert {
    condition     = github_team_repository.this["ops"].team_id == "operations"
    error_message = "Team should be set on existing repo."
  }

  assert {
    condition     = github_team_repository.this["ops"].permission == "triage"
    error_message = "Team permission should be triage on existing repo."
  }
}

# =============================================================================
# files_dir - directory-based file content
# =============================================================================

run "files_dir_loads_directory" {
  command = apply

  variables {
    name      = "test-repo"
    files_dir = "tests/unit/fixtures/content"
  }

  assert {
    condition     = length(github_repository_file.this) == 2
    error_message = "Should create 2 repository files from the directory."
  }

  assert {
    condition     = github_repository_file.this["hello.txt"].file == "hello.txt"
    error_message = "hello.txt file path should be set correctly."
  }

  assert {
    condition     = github_repository_file.this["sub/nested.txt"].file == "sub/nested.txt"
    error_message = "sub/nested.txt file path should be set correctly."
  }

  assert {
    condition     = github_repository_file.this["hello.txt"].content == "hello world\n"
    error_message = "hello.txt content should match the fixture file."
  }

  assert {
    condition     = github_repository_file.this["sub/nested.txt"].content == "nested content\n"
    error_message = "sub/nested.txt content should match the fixture file."
  }

  assert {
    condition     = length(output.files) == 2
    error_message = "Files output should contain 2 entries from the directory."
  }
}

run "files_and_files_dir_mutually_exclusive" {
  command = plan

  variables {
    name      = "test-repo"
    files_dir = "tests/unit/fixtures/content"
    files = {
      "extra.txt" = "extra"
    }
  }

  expect_failures = [
    var.files_dir,
  ]
}

run "files_dir_null_with_files_allowed" {
  command = apply

  variables {
    name      = "test-repo"
    files_dir = null
    files = {
      "README.md" = "# Hello"
    }
  }

  assert {
    condition     = length(github_repository_file.this) == 1
    error_message = "Should create 1 file from the files map when files_dir is null."
  }

  assert {
    condition     = github_repository_file.this["README.md"].content == "# Hello"
    error_message = "File content should come from the files map."
  }
}

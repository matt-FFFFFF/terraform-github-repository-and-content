# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------

resource "github_repository_environment" "this" {
  repository          = var.repository
  environment         = var.environment
  wait_timer          = var.wait_timer
  can_admins_bypass   = var.can_admins_bypass
  prevent_self_review = var.prevent_self_review

  dynamic "reviewers" {
    for_each = var.reviewers != null ? [var.reviewers] : []
    content {
      teams = reviewers.value.teams
      users = reviewers.value.users
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = var.deployment_policy != null ? [var.deployment_policy] : []
    content {
      protected_branches     = deployment_branch_policy.value.protected_branches
      custom_branch_policies = deployment_branch_policy.value.custom_branch_policies
    }
  }
}

# -----------------------------------------------------------------------------
# Environment variables
# -----------------------------------------------------------------------------

resource "github_actions_environment_variable" "this" {
  for_each = var.variables

  repository    = var.repository
  environment   = github_repository_environment.this.environment
  variable_name = each.value.name
  value         = each.value.value
}

# -----------------------------------------------------------------------------
# Environment secrets (names only — values managed externally)
# -----------------------------------------------------------------------------

resource "github_actions_environment_secret" "this" {
  for_each = var.secrets

  repository      = var.repository
  environment     = github_repository_environment.this.environment
  secret_name     = each.value.name
  plaintext_value = "REPLACE_ME"

  lifecycle {
    ignore_changes = [plaintext_value]
  }
}

# -----------------------------------------------------------------------------
# Custom deployment policies (branches and tags)
# -----------------------------------------------------------------------------

locals {
  deployment_policies = merge(
    { for bp in var.branch_policies : "branch:${bp}" => { branch_pattern = bp, tag_pattern = null } },
    { for tp in var.tag_policies : "tag:${tp}" => { branch_pattern = null, tag_pattern = tp } }
  )
}

resource "github_repository_environment_deployment_policy" "this" {
  for_each = local.deployment_policies

  repository     = var.repository
  environment    = github_repository_environment.this.environment
  branch_pattern = each.value.branch_pattern
  tag_pattern    = each.value.tag_pattern
}

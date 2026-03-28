# -----------------------------------------------------------------------------
# Repository environments
# -----------------------------------------------------------------------------

module "environment" {
  source   = "./modules/environment"
  for_each = var.environments

  repository          = local.repository
  environment         = each.value.environment
  wait_timer          = each.value.wait_timer
  can_admins_bypass   = each.value.can_admins_bypass
  prevent_self_review = each.value.prevent_self_review
  reviewers           = each.value.reviewers
  variables           = each.value.variables
  secrets             = each.value.secrets
  deployment_policy   = each.value.deployment_policy
  branch_policies     = each.value.branch_policies
  tag_policies        = each.value.tag_policies
}

locals {
  target_branch = coalesce(var.branch, var.default_branch)
  repository    = var.create_repository ? github_repository.this[0].name : var.name
}

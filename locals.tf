locals {
  target_branch = var.branch != null && var.branch != var.default_branch ? github_branch.target[0].branch : (var.create_repository ? github_branch_default.this[0].branch : var.default_branch)
  repository    = var.create_repository ? github_repository.this[0].name : var.name
}

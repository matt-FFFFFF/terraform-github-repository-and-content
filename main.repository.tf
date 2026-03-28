# -----------------------------------------------------------------------------
# Repository
# -----------------------------------------------------------------------------

resource "github_repository" "this" {
  count = var.create_repository ? 1 : 0

  name        = var.name
  description = var.description
  visibility  = var.visibility

  auto_init          = var.auto_init
  gitignore_template = var.gitignore_template
  license_template   = var.license_template
  archive_on_destroy = var.archive_on_destroy

  has_issues   = var.has_issues
  has_projects = var.has_projects
  has_wiki     = var.has_wiki

  dynamic "template" {
    for_each = var.template != null ? [var.template] : []

    content {
      owner      = template.value.owner
      repository = template.value.repository
    }
  }
}

# -----------------------------------------------------------------------------
# Default branch
# -----------------------------------------------------------------------------

resource "github_branch_default" "this" {
  count = var.create_repository ? 1 : 0

  repository = github_repository.this[0].name
  branch     = var.default_branch
}

# -----------------------------------------------------------------------------
# Branch (when targeting a non-default branch)
# -----------------------------------------------------------------------------

resource "github_branch" "target" {
  count = var.branch != null && var.branch != var.default_branch ? 1 : 0

  repository    = local.repository
  branch        = var.branch
  source_branch = var.default_branch

  depends_on = [github_repository.this]
}

# -----------------------------------------------------------------------------
# File content
# -----------------------------------------------------------------------------

resource "github_repository_file" "this" {
  for_each = var.files

  repository          = local.repository
  branch              = local.target_branch
  file                = each.key
  content             = each.value
  overwrite_on_create = true

  commit_message = "${var.commit_message_prefix}update ${each.key}"
  commit_author  = var.commit_author
  commit_email   = var.commit_email

  depends_on = [
    github_repository.this,
    github_branch_default.this,
    github_branch.target,
  ]
}

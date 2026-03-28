output "repository" {
  description = "The full repository resource (null when create_repository is false)."
  value       = var.create_repository ? github_repository.this[0] : null
}

output "full_name" {
  description = "The full name of the repository (owner/name)."
  value       = var.create_repository ? github_repository.this[0].full_name : null
}

output "html_url" {
  description = "The URL to the repository on GitHub."
  value       = var.create_repository ? github_repository.this[0].html_url : null
}

output "ssh_clone_url" {
  description = "SSH clone URL of the repository."
  value       = var.create_repository ? github_repository.this[0].ssh_clone_url : null
}

output "http_clone_url" {
  description = "HTTP clone URL of the repository."
  value       = var.create_repository ? github_repository.this[0].http_clone_url : null
}

output "default_branch" {
  description = "The default branch of the repository."
  value       = var.default_branch
}

output "files" {
  description = "Map of managed file paths to their commit SHAs."
  value       = { for k, v in github_repository_file.this : k => v.commit_sha }
}

output "actions_oidc_subject_claims" {
  description = "The OIDC subject claim customization template for GitHub Actions (null when not managed)."
  value       = var.actions_oidc_subject_claims != null ? github_actions_repository_oidc_subject_claim_customization_template.this[0] : null
}

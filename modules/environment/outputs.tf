output "environment" {
  description = "The environment resource."
  value       = github_repository_environment.this
}

output "variables" {
  description = "Map of environment variable names to their resources."
  value       = github_actions_environment_variable.this
}

output "secrets" {
  description = "Map of environment secret names (values are not exposed)."
  value = {
    for k, v in github_actions_environment_secret.this : k => {
      secret_name = v.secret_name
      created_at  = v.created_at
      updated_at  = v.updated_at
    }
  }
}

output "deployment_policies" {
  description = "Map of deployment policy keys to their resources."
  value       = github_repository_environment_deployment_policy.this
}

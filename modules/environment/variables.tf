variable "repository" {
  description = <<-DESCRIPTION
    The name of the repository to create the environment in.
  DESCRIPTION
  type        = string
  nullable    = false
}

variable "environment" {
  description = <<-DESCRIPTION
    The name of the environment.
  DESCRIPTION
  type        = string
  nullable    = false
}

variable "wait_timer" {
  description = <<-DESCRIPTION
    Amount of time in minutes to delay a job after the job is initially triggered.
  DESCRIPTION
  type        = number
  default     = 0
}

variable "can_admins_bypass" {
  description = <<-DESCRIPTION
    Whether repository admins can bypass the environment protections. Defaults to true.
  DESCRIPTION
  type        = bool
  default     = true
}

variable "prevent_self_review" {
  description = <<-DESCRIPTION
    Whether users are prevented from approving workflows runs that they triggered. Defaults to false.
  DESCRIPTION
  type        = bool
  default     = false
}

variable "reviewers" {
  description = <<-DESCRIPTION
    Reviewers who may approve deployments to this environment.
    `teams` - Up to 6 team IDs who may review jobs that reference the environment.
    `users` - Up to 6 user IDs who may review jobs that reference the environment.
  DESCRIPTION
  type = object({
    teams = optional(set(number), [])
    users = optional(set(number), [])
  })
  default = null
}

variable "variables" {
  description = <<-DESCRIPTION
    Map of environment variables to create.
    The map key is an arbitrary identifier to avoid known-after-apply issues.
    `name`  - The name of the environment variable.
    `value` - The value of the environment variable.
  DESCRIPTION
  type = map(object({
    name  = string
    value = string
  }))
  default  = {}
  nullable = false
}

variable "secrets" {
  description = <<-DESCRIPTION
    Map of environment secrets to create. Values are NOT managed by Terraform.
    The map key is an arbitrary identifier to avoid known-after-apply issues.
    `name` - The name of the secret.
    Secrets are created with a placeholder and lifecycle ignore_changes
    on plaintext_value. Set actual values via GitHub UI, CLI, or API after creation.
  DESCRIPTION
  type = map(object({
    name = string
  }))
  default  = {}
  nullable = false
}

variable "deployment_policy" {
  description = <<-DESCRIPTION
    Deployment branch policy for the environment.
    `protected_branches`     - Whether only branches with branch protection rules can deploy.
    `custom_branch_policies` - Whether only branches/tags matching specified patterns can deploy.
                               Set to true to use branch_policies and tag_policies variables.
  DESCRIPTION
  type = object({
    protected_branches     = optional(bool, false)
    custom_branch_policies = optional(bool, false)
  })
  default = null
}

variable "branch_policies" {
  description = <<-DESCRIPTION
    Branch name patterns for custom deployment policies.
    Requires deployment_policy with custom_branch_policies = true.
  DESCRIPTION
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = length(var.branch_policies) == 0 || (var.deployment_policy != null && var.deployment_policy.custom_branch_policies)
    error_message = "branch_policies requires deployment_policy with custom_branch_policies = true."
  }
}

variable "tag_policies" {
  description = <<-DESCRIPTION
    Tag name patterns for custom deployment policies.
    Requires deployment_policy with custom_branch_policies = true.
  DESCRIPTION
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = length(var.tag_policies) == 0 || (var.deployment_policy != null && var.deployment_policy.custom_branch_policies)
    error_message = "tag_policies requires deployment_policy with custom_branch_policies = true."
  }
}

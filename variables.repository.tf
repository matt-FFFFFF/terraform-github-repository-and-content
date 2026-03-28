variable "create_repository" {
  description = "Whether to create the GitHub repository. Set to false to manage content in an existing repo."
  type        = bool
  default     = true
  nullable    = false
}

variable "name" {
  description = "The name of the repository."
  type        = string
  nullable    = false
}

variable "description" {
  description = "A description of the repository."
  type        = string
  default     = null
}

variable "visibility" {
  description = "Repository visibility: public, private, or internal."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "internal"], var.visibility)
    error_message = "Visibility must be one of: public, private, internal."
  }
}

variable "default_branch" {
  description = "The name of the default branch."
  type        = string
  default     = "main"
  nullable    = false
}

variable "template" {
  description = "Template repository to use when creating the repo. Object with owner and repository keys."
  type = object({
    owner      = string
    repository = string
  })
  default = null
}

variable "files" {
  description = "Map of file paths to file content to commit to the repository. The map key is the file path within the repo."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "branch" {
  description = "Branch to commit files to. Defaults to the default branch."
  type        = string
  default     = null
}

variable "commit_author" {
  description = "The commit author name for file commits."
  type        = string
  default     = "Terraform"
}

variable "commit_email" {
  description = "The commit author email for file commits."
  type        = string
  default     = "terraform@localhost"
}

variable "commit_message_prefix" {
  description = "Prefix for auto-generated commit messages."
  type        = string
  default     = "terraform: "
}

variable "auto_init" {
  description = "Whether to produce an initial commit with an empty README in the repository."
  type        = bool
  default     = true
  nullable    = false
}

variable "gitignore_template" {
  description = "Gitignore template to use when creating the repository (e.g. Terraform, Python, Go)."
  type        = string
  default     = null
}

variable "license_template" {
  description = "License template to use when creating the repository (e.g. mit, apache-2.0)."
  type        = string
  default     = null
}

variable "archive_on_destroy" {
  description = "Archive the repository instead of deleting on destroy."
  type        = bool
  default     = true
}

variable "has_issues" {
  description = "Enable GitHub Issues on the repository."
  type        = bool
  default     = true
  nullable    = false
}

variable "has_projects" {
  description = "Enable GitHub Projects on the repository."
  type        = bool
  default     = false
  nullable    = false
}

variable "has_wiki" {
  description = "Enable the wiki on the repository."
  type        = bool
  default     = false
  nullable    = false
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

# ─── Docker ───────────────────────────────────────────────────────────────────
variable "docker_username" {
  description = "Docker Hub username"
  type        = string
  sensitive   = true
}

variable "docker_password" {
  description = "Docker Hub password or access token"
  type        = string
  sensitive   = true
}

# ─── Git ──────────────────────────────────────────────────────────────────────
variable "git_username" {
  description = "Git service username"
  type        = string
  sensitive   = true
}

variable "git_token" {
  description = "Git personal access token"
  type        = string
  sensitive   = true
}

variable "git_repo_url" {
  description = "Primary Git repository URL"
  type        = string
}

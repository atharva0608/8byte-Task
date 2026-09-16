# Docker registry credentials
resource "aws_secretsmanager_secret" "docker" {
  name                    = "${var.project_name}-${var.environment}-docker-creds"
  description             = "Docker Hub credentials for Jenkins"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-${var.environment}-docker-creds"
  }
}

resource "aws_secretsmanager_secret_version" "docker" {
  secret_id = aws_secretsmanager_secret.docker.id
  secret_string = jsonencode({
    username = var.docker_username
    password = var.docker_password
    server   = "https://index.docker.io/v1/"
  })
}

# Git / GitHub credentials
resource "aws_secretsmanager_secret" "git" {
  name                    = "${var.project_name}-${var.environment}-git-creds"
  description             = "GitHub token for Jenkins pipeline"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-${var.environment}-git-creds"
  }
}

resource "aws_secretsmanager_secret_version" "git" {
  secret_id = aws_secretsmanager_secret.git.id
  secret_string = jsonencode({
    username = var.git_username
    token    = var.git_token
    url      = var.git_repo_url
  })
}

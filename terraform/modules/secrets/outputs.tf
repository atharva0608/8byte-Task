output "docker_secret_arn" {
  description = "Docker credentials secret ARN"
  value       = aws_secretsmanager_secret.docker.arn
}

output "git_secret_arn" {
  description = "Git credentials secret ARN"
  value       = aws_secretsmanager_secret.git.arn
}

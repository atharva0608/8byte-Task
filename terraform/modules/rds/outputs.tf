output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "rds_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

# Secret ARN — pass this to apps, never the password itself
output "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials"
  value       = aws_secretsmanager_secret.db.arn
}

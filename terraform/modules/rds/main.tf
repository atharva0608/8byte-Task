# Generated DB password — never stored in tfvars
resource "random_password" "db" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secrets Manager secret
resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.project_name}-${var.environment}-db-creds"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-${var.environment}-db-creds"
  }
}

# Store full connection bundle as JSON
resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
  })
}

# DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "rds-${var.project_name}-${var.environment}-db-sg"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "main" {
  identifier     = "db-${var.project_name}-${var.environment}-postgres"
  engine         = var.rds_engine
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class
  db_name        = var.db_name
  username       = var.db_username
  password       = random_password.db.result

  # Storage
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
  multi_az               = false
  publicly_accessible    = false

  # Backups
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Lifecycle
  skip_final_snapshot       = true
  deletion_protection       = false

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
  }
}

# ─── RDS Enhanced Monitoring Role ─────────────────────────────────────────────
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

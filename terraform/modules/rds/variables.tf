variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "rds_engine" {
  description = "RDS engine"
  type        = string
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Master DB username"
  type        = string
}

variable "backup_retention_period" {
  description = "Backup retention in days"
  type        = number
}

variable "db_subnet_ids" {
  description = "DB private subnet IDs"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "RDS security group ID"
  type        = string
}

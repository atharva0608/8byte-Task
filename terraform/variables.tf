# ─── Global ───────────────────────────────────────────────────────────────────
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

# ─── VPC ──────────────────────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "availability_zones" {
  description = "Two availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "eks_subnet_cidrs" {
  description = "Private EKS subnet CIDRs"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "Private DB subnet CIDRs"
  type        = list(string)
}

# ─── EKS ──────────────────────────────────────────────────────────────────────
variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "eks_version" {
  description = "EKS Kubernetes version"
  type        = string
}

variable "eks_node_instance_type" {
  description = "EKS node instance type"
  type        = string
}

variable "eks_desired_nodes" {
  description = "Desired node count"
  type        = number
}

variable "eks_min_nodes" {
  description = "Minimum node count"
  type        = number
}

variable "eks_max_nodes" {
  description = "Maximum node count"
  type        = number
}

# ─── Jenkins ──────────────────────────────────────────────────────────────────
variable "jenkins_instance_type" {
  description = "Jenkins EC2 instance type"
  type        = string
}



variable "jenkins_key_name" {
  description = "EC2 key pair name for Jenkins"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR allowed for Jenkins SSH/UI"
  type        = string
}

# ─── RDS ──────────────────────────────────────────────────────────────────────
variable "rds_engine" {
  description = "RDS engine (postgres)"
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
  description = "Database master username"
  type        = string
}


variable "backup_retention_period" {
  description = "RDS backup retention days"
  type        = number
}

# ─── Service Credentials ──────────────────────────────────────────────────────
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


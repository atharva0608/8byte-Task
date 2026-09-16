# ─── VPC ──────────────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "eks_subnet_ids" {
  description = "EKS private subnet IDs"
  value       = module.vpc.eks_subnet_ids
}

output "database_subnet_ids" {
  description = "DB private subnet IDs"
  value       = module.vpc.database_subnet_ids
}

# ─── EKS ──────────────────────────────────────────────────────────────────────
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

# ─── Jenkins ──────────────────────────────────────────────────────────────────
output "jenkins_public_ip" {
  description = "Jenkins EC2 public IP"
  value       = module.jenkins.public_ip
}

# ─── RDS ──────────────────────────────────────────────────────────────────────
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.rds_endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials"
  value       = module.rds.db_secret_arn
}

# ─── Service Secrets ──────────────────────────────────────────────────────────
output "docker_secret_arn" {
  description = "Docker Hub credentials secret ARN"
  value       = module.secrets.docker_secret_arn
}

output "git_secret_arn" {
  description = "Git credentials secret ARN"
  value       = module.secrets.git_secret_arn
}


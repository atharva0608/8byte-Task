module "vpc" {
  source = "./modules/vpc"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  eks_subnet_cidrs    = var.eks_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
  admin_cidr   = var.admin_cidr
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

module "eks" {
  source = "./modules/eks"

  project_name           = var.project_name
  environment            = var.environment
  eks_cluster_name       = var.eks_cluster_name
  eks_version            = var.eks_version
  eks_subnet_ids         = module.vpc.eks_subnet_ids
  eks_sg_id              = module.security_groups.eks_sg_id
  cluster_role_arn       = module.iam.eks_cluster_role_arn
  node_role_arn          = module.iam.eks_node_role_arn
  eks_node_instance_type = var.eks_node_instance_type
  eks_desired_nodes      = var.eks_desired_nodes
  eks_min_nodes          = var.eks_min_nodes
  eks_max_nodes          = var.eks_max_nodes
  backend_pod_role_arn   = module.iam.backend_pod_role_arn
  alb_controller_role_arn = module.iam.alb_controller_role_arn
}

module "jenkins" {
  source = "./modules/jenkins"

  project_name          = var.project_name
  environment           = var.environment
  jenkins_instance_type = var.jenkins_instance_type
  jenkins_key_name      = var.jenkins_key_name
  jenkins_sg_id         = module.security_groups.jenkins_sg_id
  jenkins_role_name     = module.iam.jenkins_instance_profile_name
  public_subnet_id      = module.vpc.public_subnet_ids[0]
}

module "rds" {
  source = "./modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  rds_engine              = var.rds_engine
  rds_engine_version      = var.rds_engine_version
  rds_instance_class      = var.rds_instance_class
  db_name                 = var.db_name
  db_username             = var.db_username
  backup_retention_period = var.backup_retention_period
  db_subnet_ids           = module.vpc.database_subnet_ids
  rds_sg_id               = module.security_groups.rds_sg_id
}

module "secrets" {
  source = "./modules/secrets"

  project_name    = var.project_name
  environment     = var.environment
  docker_username = var.docker_username
  docker_password = var.docker_password
  git_username    = var.git_username
  git_token       = var.git_token
  git_repo_url    = var.git_repo_url
}


variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "eks_version" {
  description = "Kubernetes version"
  type        = string
}

variable "eks_subnet_ids" {
  description = "Private EKS subnet IDs"
  type        = list(string)
}

variable "eks_sg_id" {
  description = "EKS security group ID"
  type        = string
}

variable "cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  type        = string
}

variable "node_role_arn" {
  description = "EKS node IAM role ARN"
  type        = string
}

variable "eks_node_instance_type" {
  description = "Node instance type"
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

variable "backend_pod_role_arn" {
  description = "IAM Role ARN for the Backend Pod Identity"
  type        = string
}

variable "alb_controller_role_arn" {
  description = "IAM Role ARN for ALB Controller Pod Identity"
  type        = string
}

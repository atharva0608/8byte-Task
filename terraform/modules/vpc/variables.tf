variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones list"
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

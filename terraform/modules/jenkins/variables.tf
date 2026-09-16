variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}



variable "jenkins_instance_type" {
  description = "Jenkins EC2 instance type"
  type        = string
}

variable "jenkins_key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "jenkins_sg_id" {
  description = "Jenkins security group ID"
  type        = string
}

variable "jenkins_role_name" {
  description = "Jenkins IAM instance profile name"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for Jenkins"
  type        = string
}

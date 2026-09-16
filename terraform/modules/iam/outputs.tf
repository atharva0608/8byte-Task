output "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "EKS node IAM role ARN"
  value       = aws_iam_role.eks_node.arn
}

output "jenkins_role_arn" {
  description = "Jenkins IAM role ARN"
  value       = aws_iam_role.jenkins.arn
}

output "jenkins_instance_profile_name" {
  description = "Jenkins instance profile name"
  value       = aws_iam_instance_profile.jenkins.name
}

output "backend_pod_role_arn" {
  description = "Backend Pod Identity IAM role ARN"
  value       = aws_iam_role.backend_pod_role.arn
}

output "alb_controller_role_arn" {
  description = "ALB Controller Pod Identity IAM role ARN"
  value       = aws_iam_role.alb_controller_role.arn
}

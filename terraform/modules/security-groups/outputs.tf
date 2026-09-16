output "alb_sg_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "eks_sg_id" {
  description = "EKS security group ID"
  value       = aws_security_group.eks.id
}

output "jenkins_sg_id" {
  description = "Jenkins security group ID"
  value       = aws_security_group.jenkins.id
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

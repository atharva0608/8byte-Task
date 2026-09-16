output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "eks_subnet_ids" {
  description = "EKS private subnet IDs"
  value       = aws_subnet.eks[*].id
}

output "database_subnet_ids" {
  description = "DB private subnet IDs"
  value       = aws_subnet.database[*].id
}

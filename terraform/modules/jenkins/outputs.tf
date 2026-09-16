output "instance_id" {
  description = "Jenkins EC2 instance ID"
  value       = aws_instance.jenkins.id
}

output "public_ip" {
  description = "Jenkins EC2 public IP"
  value       = aws_instance.jenkins.public_ip
}

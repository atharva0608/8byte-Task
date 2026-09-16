data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Jenkins EC2 instance
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = var.jenkins_instance_type
  key_name               = var.jenkins_key_name
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.jenkins_sg_id]
  iam_instance_profile   = var.jenkins_role_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    yum update -y
    
    # 1. Install Java & Jenkins
    dnf install -y java-17-amazon-corretto wget unzip
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    yum install -y jenkins
    
    # Configure Controller Executors
    mkdir -p /var/lib/jenkins/init.groovy.d/
    cat << 'GROOVY' > /var/lib/jenkins/init.groovy.d/set-executors.groovy
import jenkins.model.*
Jenkins.instance.setNumExecutors(2)
Jenkins.instance.save()
GROOVY
    chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/

    systemctl enable jenkins
    systemctl start jenkins

    # 2. Install Docker
    yum install -y docker
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user
    usermod -aG docker jenkins
    systemctl restart jenkins

    # 3. Install kubectl (1.31)
    curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.31.0/2024-09-12/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    mv ./kubectl /usr/local/bin

    # 4. Install Helm
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh

    # 5. Install AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    # 6. Install Trivy (Container Scanner)
    rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.48.3/trivy_0.48.3_Linux-64bit.rpm
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-jenkins"
  }
}

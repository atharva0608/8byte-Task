# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.eks_cluster_name
  role_arn = var.cluster_role_arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = var.eks_subnet_ids
    security_group_ids      = [var.eks_sg_id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Name = var.eks_cluster_name
  }
}

# Launch template — names each node EC2 instance
resource "aws_launch_template" "node" {
  name_prefix = "${var.eks_cluster_name}-node-"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.eks_cluster_name}-node"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.eks_cluster_name}-node-vol"
    }
  }

  tags = {
    Name = "${var.eks_cluster_name}-lt"
  }
}

# Managed node group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.eks_cluster_name}-ng"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.eks_subnet_ids
  instance_types  = [var.eks_node_instance_type]

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  scaling_config {
    desired_size = var.eks_desired_nodes
    min_size     = var.eks_min_nodes
    max_size     = var.eks_max_nodes
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = "${var.eks_cluster_name}-ng"
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
  }
}

# ─── EKS Pod Identity ───────────────────────────────────────────────────────────
resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"
  
  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "amazon-cloudwatch-observability"
  
  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = var.backend_pod_role_arn
}

resource "aws_eks_pod_identity_association" "alb_controller" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = var.alb_controller_role_arn
}

# 8byte — AWS Terraform Infrastructure

Modular Terraform configuration that provisions the complete AWS infrastructure for the 8byte DevOps assignment.

---

## Architecture

```text
AWS (us-east-1)
│
├── VPC  10.0.0.0/16
│
├── Public Subnet A  (us-east-1a)   ← Jenkins EC2
├── Public Subnet B  (us-east-1b)
│
├── Private EKS Subnet A  (us-east-1a)  ← EKS nodes
├── Private EKS Subnet B  (us-east-1b)  ← EKS nodes
│
├── Private DB Subnet A  (us-east-1a)   ← RDS
├── Private DB Subnet B  (us-east-1b)   ← RDS
│
├── IAM Roles & Pod Identity
│   ├── EKS Cluster Role
│   ├── EKS Node Role (with CloudWatch Agent Server Policy)
│   ├── Backend Pod Identity Role (Access DB Secret)
│   ├── ALB Controller Pod Identity Role
│   └── Jenkins EC2 Role
│
├── EKS Cluster 1.31 (private subnets)
│   ├── Managed Node Group
│   ├── AWS Load Balancer Controller (Helm)
│   ├── External Secrets Operator (Helm)
│   ├── Amazon CloudWatch Observability (Addon)
│   └── Prometheus & Grafana Stack (Helm)
│
├── Jenkins EC2 (public subnet A)
│   └── Fully automated CI/CD pipeline (Trivy, Tests, Staging/Prod)
│
└── RDS PostgreSQL (private DB subnets)
    └── Enhanced Monitoring (CloudWatch)
```

---

## Directory Structure

```text
terraform/
├── main.tf                    # Root module — calls all child modules
├── variables.tf               # Root variable declarations
├── outputs.tf                 # Root outputs
├── providers.tf               # AWS provider + default tags
├── versions.tf                # Terraform + provider version pins
├── backend.tf                 # S3 remote state backend
├── terraform.tfvars.example   # Example variable values (safe to commit)
├── .gitignore                 # Excludes state, secrets and .terraform/
└── modules/
    ├── vpc/                   # VPC, subnets, IGW, NAT, route tables
    ├── security-groups/       # ALB, EKS, Jenkins, RDS security groups
    ├── iam/                   # EKS cluster/node roles + Jenkins EC2 role
    ├── eks/                   # EKS cluster and managed node group
    ├── jenkins/               # Jenkins EC2 instance
    └── rds/                   # PostgreSQL RDS instance and subnet group
```

---

## Prerequisites

| Tool      | Version  |
|-----------|----------|
| Terraform | ≥ 1.5.0  |
| AWS CLI   | ≥ 2.x    |

AWS credentials must be configured (`aws configure` or environment variables). The IAM principal must have sufficient permissions to create VPC, EKS, EC2, RDS and IAM resources.

---

## Quick Start

### 1. Create the S3 state backend (one-time)

```bash
aws s3api create-bucket \
  --bucket 8byte-terraform-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket 8byte-terraform-state \
  --versioning-configuration Status=Enabled
```

### 2. Configure variables

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set real values, never commit this file
```

### 3. Deploy

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Connect to EKS

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name 8byte-eks
```

### 5. Destroy

```bash
terraform destroy
```

---

## Key Variables

| Variable | Description | Example |
|---|---|---|
| `aws_region` | AWS region | `us-east-1` |
| `project_name` | Resource name prefix | `8byte` |
| `environment` | Deployment environment | `dev` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `availability_zones` | Two AZs | `["us-east-1a", "us-east-1b"]` |
| `eks_cluster_name` | EKS cluster name | `8byte-eks` |
| `eks_version` | Kubernetes version | `1.29` |
| `eks_node_instance_type` | Node type | `t3.medium` |
| `eks_desired_nodes` | Desired node count | `2` |
| `jenkins_instance_type` | Jenkins EC2 type | `t3.medium` |
| `admin_cidr` | Allowed IP for Jenkins | `203.0.113.10/32` |
| `rds_instance_class` | RDS instance class | `db.t3.micro` |
| `backup_retention_period` | RDS backup days | `7` |

---

## Module Dependency Graph

```text
                    ┌─────────────────┐
                    │   vpc module    │
                    └────────┬────────┘
              vpc_id         │   subnet IDs
         ┌───────────────────┼──────────────────┐
         ▼                   ▼                  ▼
┌────────────────┐  ┌──────────────┐   ┌──────────────┐
│ security-groups│  │  eks module  │   │  rds module  │
└───────┬────────┘  └──────────────┘   └──────────────┘
  sg IDs│
   ┌────┴───────────────────┐
   ▼                        ▼
┌──────────┐         ┌─────────────┐
│   eks    │         │   jenkins   │
└──────────┘         └─────────────┘
         ▲
         │  role ARNs
┌────────┴────────┐
│   iam module   │
└─────────────────┘
```

---

## Best Practices

| Practice | Reason |
|---|---|
| **EKS nodes in private subnets** | Worker nodes have no public IPs; the attack surface is reduced. External traffic enters only through the ALB or NAT gateway. |
| **RDS in private DB subnets** | The database is unreachable from the internet. `publicly_accessible = false` enforces this at the API level. |
| **RDS port 5432 restricted to EKS/Jenkins SGs** | Least-privilege networking: only application-tier security groups can reach Postgres. No broad CIDR rules. |
| **Jenkins SSH/UI restricted to `admin_cidr`** | Limits exposure of the CI server to known IPs. Set `admin_cidr` to your actual IP, not `0.0.0.0/0`, in production. |
| **IAM roles instead of hardcoded credentials** | EC2 and EKS nodes assume IAM roles via instance metadata. No long-lived access keys in config files or environment variables. |
| **S3 backend with Native State Locking** | Remote state is shared and native S3 `use_lockfile = true` prevents concurrent corruptions. |
| **`sensitive = true` on `db_password`** | Prevents the password from appearing in plan output or logs. Use AWS Secrets Manager in production. |
| **Two Availability Zones** | EKS nodes and DB subnets span two AZs for basic fault tolerance without over-engineering. |
| **RDS automated backups & Monitoring** | Configured with retention periods and CloudWatch Enhanced Monitoring for metrics. |
| **EKS Pod Identity** | Utilized instead of IRSA for granting specific AWS Secrets Manager access to the backend application, adhering to least privilege. |
| **Staging and Production Separation** | Kustomize overlays separate `staging` and `production` namespaces. |
| **Immutable Docker Tags** | Jenkins uses exact Git SHAs instead of `latest` tags to deploy to staging and production identically. |
| **Security Scanning** | Pipeline includes Trivy for container scanning and npm/pip audits for dependency checking. |
| **CloudWatch and Prometheus** | Application logs are funneled to CloudWatch via FluentBit. EKS nodes run Prometheus Node Exporter with Grafana dashboards. |

---

## Outputs

| Output | Description |
|---|---|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | Public subnet IDs |
| `eks_subnet_ids` | Private EKS subnet IDs |
| `database_subnet_ids` | Private DB subnet IDs |
| `eks_cluster_name` | EKS cluster name |
| `eks_cluster_endpoint` | EKS API server endpoint |
| `jenkins_public_ip` | Jenkins EC2 public IP |
| `rds_endpoint` | RDS instance endpoint |

---

## Security Notes

- **Never commit `terraform.tfvars`** — it is listed in `.gitignore`.
- Restrict `admin_cidr` to a specific IP range before deploying to production.
- Enable AWS CloudTrail and VPC Flow Logs for auditing in production environments.

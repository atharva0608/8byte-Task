# Final Project Report: 8byte DevOps Engineering Platform

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Repository Structure](#2-repository-structure)
3. [Network Architecture (VPC)](#3-network-architecture-vpc)
4. [Container Orchestration (EKS)](#4-container-orchestration-eks)
5. [Database (RDS PostgreSQL)](#5-database-rds-postgresql)
6. [CI/CD Infrastructure (Jenkins EC2)](#6-cicd-infrastructure-jenkins-ec2)
7. [IAM & Security Architecture](#7-iam--security-architecture)
8. [Secret Management Flow](#8-secret-management-flow)
9. [Platform Add-ons (Helm/Terraform)](#9-platform-add-ons-helmterraform)
10. [GitOps Deployment (Argo CD)](#10-gitops-deployment-argo-cd)
11. [CI/CD Pipeline (Jenkinsfile)](#11-cicd-pipeline-jenkinsfile)
12. [Application Architecture](#12-application-architecture)
13. [Kubernetes Manifests](#13-kubernetes-manifests)
14. [Monitoring & Observability](#14-monitoring--observability)
15. [Terraform State & Locking](#15-terraform-state--locking)
16. [Automation Matrix](#16-automation-matrix)
17. [Configuration Reference](#17-configuration-reference)
18. [Known Simplifications & Production Evolution Path](#18-known-simplifications--production-evolution-path)

---

## 1. Executive Summary

The 8byte platform is a fully-automated, production-style DevOps assignment implementing the complete software delivery lifecycle from infrastructure provisioning to application deployment, monitoring, and self-healing.

The platform demonstrates:
- **Infrastructure as Code** using modular Terraform (7 modules, ~800 lines of HCL)
- **GitOps deployments** via Argo CD (Pull-based, self-healing, continuous sync)
- **Push-gated CI/CD** via Jenkins with automated security scanning (Trivy, pip-audit, npm audit)
- **Zero-plaintext secrets** — the database password is never stored in source code, tfvars, or CI/CD environment variables
- **Least-privilege IAM** — EKS Pod Identity per workload, Jenkins has no DB access
- **Automated infrastructure provisioning, platform add-on installation, CI/CD, GitOps deployment, monitoring, scaling, and rollback, with only required one-time bootstrap activities and production approval remaining manual.**

| Layer | Technology | Provisioning |
|---|---|---|
| Networking | AWS VPC, Subnets, NAT GW, IGW | Terraform |
| Compute (Cluster) | AWS EKS 1.35 | Terraform |
| Compute (CI/CD) | AWS EC2 t3.medium | Terraform |
| Database | AWS RDS PostgreSQL 15 | Terraform |
| Secret Storage | AWS Secrets Manager | Terraform |
| State Storage | AWS S3 (native lockfile) | Manual one-time |
| ALB | AWS ALB via AWS LB Controller | Terraform (Helm) |
| GitOps | Argo CD | Terraform (Helm) |
| Secrets Sync | External Secrets Operator | Terraform (Helm) |
| Node Autoscaler | Cluster Autoscaler | Terraform (Helm) |
| Monitoring | Prometheus + Grafana | Terraform (Helm) |
| Backend | FastAPI (Python 3.12) | Argo CD |
| Frontend | React (Nginx) | Argo CD |

---

## 2. Repository Structure

```text
8byte/
├── Jenkinsfile                     # Full CI/CD pipeline (GitOps model)
├── README.md                       # Quick-start guide
├── docs/
│   └── final-project-report.md    # This document
├── demo-application/
│   ├── docker-compose.yml          # Local dev environment
│   ├── .env.example                # Local dev variables template
│   ├── backend/                    # FastAPI application
│   │   ├── Dockerfile              # python:3.12-slim, non-root user
│   │   ├── requirements.txt        # pinned Python dependencies
│   │   ├── src/order_service/      # Application code
│   │   ├── alembic/                # DB migrations
│   │   └── tests/                  # pytest suite (unit + integration)
│   ├── frontend/                   # React application
│   │   └── Dockerfile
│   └── kubernetes/
│       ├── argocd-app.yaml         # Argo CD Application resources (staging + production)
│       ├── base/                   # Base Kustomize manifests (shared)
│       │   ├── backend.yaml        # Deployment + Service
│       │   ├── frontend.yaml       # Deployment + Service
│       │   ├── ingress.yaml        # ALB Ingress (internet-facing)
│       │   ├── hpa.yaml            # HorizontalPodAutoscaler
│       │   ├── pdb.yaml            # PodDisruptionBudget
│       │   ├── secrets.yaml        # ClusterSecretStore + ExternalSecret
│       │   ├── serviceaccount.yaml # Backend ServiceAccount
│       │   ├── grafana-dashboards.yaml
│       │   └── kustomization.yaml
│       └── overlays/
│           ├── staging/            # Staging-specific patches
│           └── production/         # Production-specific patches
└── terraform/
    ├── backend.tf                  # S3 remote state + native locking
    ├── versions.tf                 # Provider version pins
    ├── providers.tf                # AWS, Helm providers
    ├── variables.tf                # All input variable definitions
    ├── terraform.tfvars            # Actual deployed values (gitignored)
    ├── terraform.tfvars.example    # Safe reference template
    ├── main.tf                     # Module orchestration
    ├── addons.tf                   # Helm releases (ALB, ESO, Prometheus, CA, ArgoCD)
    ├── outputs.tf                  # Key infrastructure outputs
    └── modules/
        ├── vpc/                    # VPC, subnets, NAT GW, IGW, route tables
        ├── security-groups/        # ALB, EKS, Jenkins, RDS security groups
        ├── iam/                    # All IAM roles and policies
        ├── eks/                    # EKS cluster, node group, EKS add-ons
        ├── jenkins/                # Jenkins EC2, user_data bootstrap
        ├── rds/                    # RDS instance, random password, Secrets Manager entry
        └── secrets/                # Docker Hub & Git token storage in Secrets Manager
```

---

## 3. Network Architecture (VPC)

**CIDR:** `10.0.0.0/16`  
**Region:** `us-west-2`  
**Availability Zones:** `us-west-2a`, `us-west-2b`

| Subnet Type | AZ A | AZ B | Purpose |
|---|---|---|---|
| **Public** | `10.0.1.0/24` | `10.0.2.0/24` | Jenkins EC2, NAT Gateway, IGW |
| **EKS Private** | `10.0.11.0/24` | `10.0.12.0/24` | EKS Managed Node Group |
| **DB Private** | `10.0.21.0/24` | `10.0.22.0/24` | RDS PostgreSQL subnet group |

**Traffic Routing:**
- Public subnets route `0.0.0.0/0` → Internet Gateway
- EKS/DB subnets route `0.0.0.0/0` → NAT Gateway (single NAT for cost)
- Internal VPC traffic stays on private routing table

---

## 4. Container Orchestration (EKS)

**Cluster Name:** `8byte-eks`  
**Kubernetes Version:** `1.35`  
**Endpoint:** Public + Private access enabled

| Configuration | Value |
|---|---|
| Node Instance Type | `t3.medium` |
| Desired Nodes | `2` |
| Minimum Nodes | `1` |
| Maximum Nodes | `4` |
| Node Disk | `gp3`, encrypted |
| Node Subnets | Private EKS subnets (both AZs) |

**EKS Managed Add-ons (provisioned by Terraform):**
- `eks-pod-identity-agent` — enables Pod-level IAM identity without node-level credentials
- `amazon-cloudwatch-observability` — ships container logs/metrics to CloudWatch

**Pod Identity Associations:**
| Service Account | Namespace | IAM Role |
|---|---|---|
| `external-secrets` | `external-secrets` | `backend-pod-role` (Secrets Manager read) |
| `aws-load-balancer-controller` | `kube-system` | `alb-controller-role` (full ALB management) |

**Cluster Autoscaler Tags on Node Group:**
```
k8s.io/cluster-autoscaler/enabled = "true"
k8s.io/cluster-autoscaler/8byte-eks = "owned"
```
These tags allow the Cluster Autoscaler (deployed via Helm) to discover and manage the ASG.

---

## 5. Database (RDS PostgreSQL)

**Identifier:** `db-8byte-dev-postgres`  
**Engine:** PostgreSQL `15.19`  
**Instance Class:** `db.t3.micro`

| Configuration | Value |
|---|---|
| Storage | 20 GB gp3 (auto-scales to 100 GB) |
| Encryption | ✅ Enabled (`storage_encrypted = true`) |
| Public Access | ❌ Disabled (`publicly_accessible = false`) |
| Multi-AZ | ❌ No (dev environment cost control) |
| Backup Retention | 7 days |
| Backup Window | `03:00–04:00 UTC` |
| Maintenance Window | `Mon 04:00–05:00 UTC` |
| Enhanced Monitoring | ✅ Enabled (60s interval, dedicated IAM role) |
| Final Snapshot | ❌ Skipped (`skip_final_snapshot = true`) — dev environment |
| Deletion Protection | ❌ Off — for clean destroy in dev |

**Password Management:**  
The password is generated by `random_password.db` (16 chars, special characters) and **never stored in tfvars**. It is stored exclusively in AWS Secrets Manager as a JSON bundle:
```json
{
  "username": "dbadmin",
  "password": "<random-16-char>",
  "host": "<rds-endpoint>",
  "port": 5432,
  "dbname": "appdb"
}
```

**Security Group Rules (RDS):**  
- **Inbound:** Port 5432 from EKS Security Group only  
- **Outbound:** All traffic to 0.0.0.0/0  
- **Jenkins has NO inbound rule** — CI integration tests run against a local ephemeral PostgreSQL container, not the real RDS.

---

## 6. CI/CD Infrastructure (Jenkins EC2)

**Instance Type:** `t3.medium`  
**AMI:** Dynamically fetched from AWS SSM Parameter Store:
```
/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64
```
This is region-agnostic and always resolves to the latest Amazon Linux 2023 AMI in the configured region. No hardcoded AMI IDs.

**Disk:** 30 GB, `gp3`, encrypted  
**Subnet:** Public subnet (accessible via SSH/8080)  
**Access:** Controlled by `admin_cidr` variable

**Automatic Bootstrapping via `user_data`:**

| Tool | Version | Purpose |
|---|---|---|
| Java (OpenJDK 11) | `amazon-linux-extras` | Jenkins runtime |
| Jenkins | Latest stable | CI/CD controller |
| Docker | Latest (yum) | Build container images |
| kubectl | `1.31.0` | EKS cluster control |
| Helm | Latest | Chart deployment |
| AWS CLI v2 | Latest | AWS API calls |
| Trivy | `v0.48.3` | Container vulnerability scanner |

**Jenkins Controller Executors:**  
A Groovy init script is placed at `/var/lib/jenkins/init.groovy.d/set-executors.groovy` during `user_data` to **set the controller executor count to `2`**. This allows the single Jenkins EC2 instance to execute the pipeline directly, avoiding the overhead of provisioning separate agent nodes for this assignment.

**Jenkins IAM Role Permissions (least privilege):**
- `AmazonSSMManagedInstanceCore` — for SSM Session Manager access
- **No Secrets Manager access** — Jenkins does not have credentials to the database

---

## 7. IAM & Security Architecture

All IAM roles follow the **Principle of Least Privilege**. There are 5 distinct IAM roles:

### 1. EKS Cluster Role
- **Trust:** `eks.amazonaws.com`  
- **Policies:** `AmazonEKSClusterPolicy`  

### 2. EKS Node Role
- **Trust:** `ec2.amazonaws.com`  
- **Policies:**
  - `AmazonEKSWorkerNodePolicy`
  - `AmazonEKS_CNI_Policy`
  - `AmazonEC2ContainerRegistryReadOnly`
  - `CloudWatchAgentServerPolicy`
  - Inline: Cluster Autoscaler actions (`autoscaling:*`, `ec2:DescribeLaunchTemplateVersions`)

### 3. Backend Pod Identity Role
- **Trust:** `pods.eks.amazonaws.com` (EKS Pod Identity — not node IRSA)  
- **Association:** `external-secrets` ServiceAccount in `external-secrets` namespace  
- **Policy:** Inline, restricted to `secretsmanager:GetSecretValue` and `secretsmanager:DescribeSecret` against only the pattern `arn:aws:secretsmanager:*:*:secret:8byte-dev-db-creds-*`

### 4. ALB Controller Pod Identity Role
- **Trust:** `pods.eks.amazonaws.com`  
- **Association:** `aws-load-balancer-controller` ServiceAccount in `kube-system`  
- **Policy:** Full ALB policy (from `alb_policy.json` — AWS official policy)

### 5. Jenkins EC2 Role
- **Trust:** `ec2.amazonaws.com`  
- **Policies:** SSM Core  
- **Explicitly missing:** No Secrets Manager, no RDS access, no ECR push permissions

**Security Group Rules Summary:**

| Group | Inbound | Outbound |
|---|---|---|
| ALB SG | 80/443 from `0.0.0.0/0` | All |
| EKS SG | Self (intra-cluster), from ALB SG | All |
| Jenkins SG | 22/8080 from `admin_cidr` | All |
| RDS SG | 5432 from EKS SG only | All |

---

## 8. Secret Management Flow

```
AWS Secrets Manager
        │
        │ (IAM: Backend Pod Identity Role - least privilege)
        ▼
External Secrets Operator (ESO)
        │
        │ (ClusterSecretStore → ExternalSecret → K8s Secret)
        ▼
Kubernetes Secret: db-credentials-secret
        │
        │ (envFrom: secretKeyRef)
        ▼
Backend Application Pod
(env vars: DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME)
```

**Key properties:**
- The DB password is generated by Terraform (`random_password`) — never typed by a human
- The password is stored in AWS Secrets Manager (and encrypted at rest in the S3 Terraform state backend)
- ESO refreshes the K8s secret every **1 hour** from Secrets Manager
- Jenkins NEVER receives the DB password

**Other secrets managed:**  
Docker Hub credentials (`docker_username`/`docker_password`) and GitHub token (`git_token`) are stored in separate Secrets Manager secrets under the `secrets` module, and referenced by Jenkins via the Jenkins credential store (manual one-time setup on first boot).

---

## 9. Platform Add-ons (Helm/Terraform)

All platform add-ons are provisioned automatically via Terraform's `helm_release` resources in `addons.tf`. They install in strict dependency order:

```
EKS Cluster + Node Group
        │
        ▼
AWS Load Balancer Controller  (depends_on: EKS)
        │
        ├──► External Secrets Operator     (depends_on: ALB Controller)
        ├──► Prometheus + Grafana          (depends_on: ALB Controller)
        ├──► Cluster Autoscaler            (depends_on: ALB Controller)
        └──► Argo CD                       (depends_on: ALB Controller)
```

The `depends_on` chain prevents the known Kubernetes Webhook race condition where the ALB Controller's mutating webhook blocks other charts from creating Services before the ALB pods are ready.

| Add-on | Namespace | Chart Source | Notes |
|---|---|---|---|
| `aws-load-balancer-controller` | `kube-system` | `aws.github.io/eks-charts` | vpcId + region injected |
| `external-secrets` | `external-secrets` | `charts.external-secrets.io` | Namespace auto-created |
| `kube-prometheus-stack` | `monitoring` | `prometheus-community` | Grafana enabled |
| `cluster-autoscaler` | `kube-system` | `kubernetes.github.io/autoscaler` | Auto-discovers via node tags |
| `argo-cd` | `argocd` | `argoproj.github.io/argo-helm` | ClusterIP service type |

> **Note on Helm Provider Authentication:** The Terraform `helm` provider authenticates to the EKS cluster by executing the `aws eks get-token` command under the hood. It is strictly required that the `aws` CLI is installed and available in the system `PATH` where Terraform is executed, otherwise Helm chart deployments will fail with a `Kubernetes cluster unreachable` error.

---

## 10. GitOps Deployment (Argo CD)

Argo CD implements the Pull-based GitOps deployment model. It continuously monitors the GitHub repository for changes to the Kubernetes manifests and automatically reconciles the cluster state.

**Two Argo CD Application CRDs:**

```yaml
# demo-application/kubernetes/argocd-app.yaml
demo-application-staging:
  source: overlays/staging  → destination namespace: staging
  syncPolicy: automated (prune + selfHeal)

demo-application-production:
  source: overlays/production → destination namespace: production
  syncPolicy: automated (prune + selfHeal)
```

**Self-Healing:** If someone manually deletes a Pod or modifies a ConfigMap directly in the cluster, Argo CD detects the drift and reverts to the Git-defined state within ~3 minutes.

**Pruning:** If a resource is removed from Git manifests, Argo CD automatically removes it from the cluster.

---

## 11. CI/CD Pipeline (Jenkinsfile)

The Jenkinsfile implements a full GitOps pipeline triggered on `testing-branch` and `main` branch:

### Branch-to-Action Mapping

| Branch | Stages Executed |
|---|---|
| `testing-branch` | Full CI: Scans → Tests → Build → Push → GitOps Commit (Staging) → Smoke Test → Rollback (if fail) → Auto PR |
| `main` (after merge) | Deploy Only: Skip Builds → Extract Validated SHA → Production Approval → GitOps Commit (Production) → Deploy |
| Any (with `ROLLBACK_SHA`) | Skips build, directly deploys the provided SHA to Production |

### Pipeline Flowchart

```text
                    GITHUB
                       │
             push testing-branch
                       │
                       ▼
               GITHUB WEBHOOK
                       │
                       ▼
                  JENKINS (Check [skip ci])
                       │
          ┌────────────┼────────────┐
          │            │            │
        Tests        Scans        Build
          │            │            │
          └────────────┼────────────┘
                       │
                  Docker Hub
                       │
                 IMAGE:SHA
                       │
                       ▼
              GitOps staging update
                       │
                       ▼
                    ARGO CD
                       │
                       ▼
                   STAGING
                       │
                 Smoke tests
                  /       \
               PASS       FAIL
                │           │
                │      Restore old SHA
                │           │
                ▼           ▼
             Create PR    FAIL BUILD
                │
                ▼
           Merge to main
                │
                ▼
              JENKINS
                │
        Extract SAME IMAGE SHA
                │
        Manual production approval
                │
                ▼
        GitOps production update
                │
                ▼
              ARGO CD
                │
                ▼
            PRODUCTION
```

**Self-Trigger Prevention:**  
To prevent an infinite loop where Jenkins pushes a GitOps commit which triggers another Jenkins build, an early pipeline initialization stage reads the git commit message. If it contains `[skip ci]`, Jenkins immediately skips all subsequent stages and exits successfully.

**Image Tagging & Promotion Strategy:**  
All images are tagged with the immutable Git SHA (`git rev-parse --short HEAD`).
The `latest` tag is never pushed or used in production.
When `testing-branch` is pushed, a new image is built, scanned, and pushed. When `main` is built, it **does not rebuild the image**. Instead, Jenkins extracts the exact same `IMAGE_TAG` that was validated in staging directly from the staging `kustomization.yaml` and deploys it to production. This guarantees the principle of "build once, promote the same artifact".

**Rollback:**  
Staging rollback is fully automated on validation failure. A `ROLLBACK_SHA` parameter allows instant rollback of Production to any previously-pushed image without rebuilding. Jenkins updates the kustomization.yaml to the old SHA and pushes, and Argo CD reverts the cluster.

**GitHub Webhook (No Actions):**  
GitHub Actions are completely removed. Jenkins acts as the sole CI/CD orchestrator, triggered by GitHub webhooks. Jenkins directly interacts with the GitHub API to generate PRs.

---

## 12. Application Architecture

### Backend — FastAPI

| Property | Value |
|---|---|
| Runtime | Python 3.12 |
| Framework | FastAPI 0.111+ |
| DB ORM | SQLAlchemy 2.0 + Alembic migrations |
| DB Driver | psycopg2-binary |
| Server | Uvicorn (ASGI) |
| Metrics | prometheus-client 0.20+ |
| Port | `8000` |

**Key API Endpoints:**
- `GET /health` — liveness probe (always 200 if process is up)
- `GET /ready` — readiness probe (200 only if DB connection succeeds)
- `GET /metrics` — Prometheus metrics endpoint (scraped by Prometheus)
- `GET/POST /api/orders` — Business logic (Order CRUD)

**Dockerfile characteristics:**
- Base image: `python:3.12-slim`
- Non-root user (`appuser`, UID 1000)
- `PYTHONDONTWRITEBYTECODE` + `PYTHONUNBUFFERED` set
- System-level `libpq-dev` installed for psycopg2

### Frontend — React

- Built as a static SPA, served via Nginx
- Communicates with backend via `/api/*` paths
- Port `80` inside container, `3000:80` in Docker Compose for local dev

### Local Development

```bash
cd demo-application
cp .env.example .env
docker compose up
# Backend: http://localhost:8000
# Frontend: http://localhost:3000
```

---

## 13. Kubernetes Manifests

All manifests are organized with Kustomize (`base` + `overlays`).

### Backend Deployment (`base/backend.yaml`)
- **Replicas:** 2 (minimum)
- **Strategy:** `RollingUpdate` (maxSurge: 1, maxUnavailable: 0 — zero downtime)
- **Security Context:** `runAsNonRoot: true`, `runAsUser: 1000`, `allowPrivilegeEscalation: false`
- **Topology Spread:** `topologyKey: topology.kubernetes.io/zone` — pods spread across AZs
- **Probes:** `/health` (liveness), `/ready` (readiness) — both on port 8000
- **Resources:** requests: 100m CPU / 128Mi RAM; limits: 250m CPU / 256Mi RAM

### External Secrets (`base/secrets.yaml`)
- `ClusterSecretStore` pointing to AWS Secrets Manager (`us-west-2`)
- `ExternalSecret` fetching `8byte-dev-db-creds` and mapping to K8s Secret `db-credentials-secret`
- Refresh interval: `1h`

### HPA (`base/hpa.yaml`)
- `minReplicas: 2`, `maxReplicas: 5`
- Target CPU Utilization: `70%`

### PDB (`base/pdb.yaml`)
- Ensures minimum pod availability during node draining

### Ingress (`base/ingress.yaml`)
- `kubernetes.io/ingress.class: alb`
- `alb.ingress.kubernetes.io/scheme: internet-facing`
- `alb.ingress.kubernetes.io/target-type: ip`
- Routes `/api` → backend-service, `/` → frontend-service

---

## 14. Monitoring & Observability

### Prometheus + Grafana (kube-prometheus-stack)
- Deployed automatically via Terraform Helm release in `monitoring` namespace
- Scrapes EKS node metrics and application `/metrics` endpoint
- Grafana is enabled within the same chart

**ConfigMap-based Grafana Dashboards (`grafana-dashboards.yaml`):**
- **8Byte Infrastructure Dashboard:** Node CPU, Memory, Disk, Network utilization
- **8Byte Application Dashboard:** HTTP request rate, error rate, latency percentiles (P50/P95/P99), business metrics (orders per minute)

### CloudWatch Observability
- `amazon-cloudwatch-observability` EKS add-on collects container logs and metrics
- Application stdout/stderr → CloudWatch Log Group (via FluentBit sidecar in the add-on)
- Kubernetes events → CloudWatch

### Centralized Access Logs (S3)
- ALB access logs are collected centrally into a dedicated S3 bucket (`8byte-access-logs-*`).
- Configured via Ingress annotations (`alb.ingress.kubernetes.io/load-balancer-attributes: access_logs.s3.enabled=true`).
- Provides a centralized retention and analysis point for all incoming HTTP/HTTPS traffic.

### RDS Enhanced Monitoring
- 60-second metric interval (CPU, connections, IOPS, free memory)
- Dedicated `rds-monitoring-role` IAM role with `AmazonRDSEnhancedMonitoringRole`

---

## 15. Terraform State & Locking

**Backend Type:** S3  
**Bucket:** `8byte-tfstate-759655305018`  
**Key:** `infra/terraform.tfstate`  
**Region:** `us-west-2`  
**Encryption:** ✅ Server-side encryption enabled  
**Locking:** ✅ Native S3 lockfile (`use_lockfile = true`) — No DynamoDB required (Terraform 1.10+)

**Provider Versions (pinned in `versions.tf`):**
| Provider | Constraint |
|---|---|
| `hashicorp/aws` | `~> 5.0` |
| `hashicorp/random` | `~> 3.0` |
| `hashicorp/helm` | `~> 2.10` |
| Terraform CLI | `>= 1.5.0` |

---

## 16. Automation Matrix

| Activity | Manual One-Time | Manual Per-Release | Fully Automated |
|---|---|---|---|
| AWS account setup | ✅ | | |
| S3 state bucket creation | ✅ | | |
| Jenkins GitHub/Docker credentials setup | ✅ | | |
| GitHub repository creation | ✅ | | |
| VPC provisioning | | | ✅ |
| EKS cluster + node group | | | ✅ |
| RDS + password generation | | | ✅ |
| DB credentials → Secrets Manager | | | ✅ |
| Jenkins EC2 + tool installation | | | ✅ |
| IAM roles + policies | | | ✅ |
| ALB Controller installation | | | ✅ |
| External Secrets Operator installation | | | ✅ |
| Prometheus + Grafana installation | | | ✅ |
| Cluster Autoscaler installation | | | ✅ |
| Argo CD installation | | | ✅ |
| Auto PR on `testing-branch` push | | | ✅ (Jenkins API call) |
| Dependency security scans | | | ✅ (Jenkins) |
| Integration tests (ephemeral DB) | | | ✅ (Jenkins) |
| Container image build | | | ✅ (Jenkins) |
| Trivy container scan | | | ✅ (Jenkins) |
| Docker Hub push (immutable SHA) | | | ✅ (Jenkins) |
| GitOps commit (kustomization update) | | | ✅ (Jenkins) |
| Staging deployment | | | ✅ (Argo CD) |
| Production deployment approval | | ✅ | |
| Production deployment | | | ✅ (Argo CD after approval) |
| Self-healing (drift correction) | | | ✅ (Argo CD) |
| Node scaling | | | ✅ (Cluster Autoscaler) |
| Pod scaling | | | ✅ (HPA) |
| Secret rotation sync | | | ✅ (ESO 1h refresh) |
| Rollback | | ✅ (trigger) | ✅ (execution via pipeline param) |

---

## 17. Configuration Reference

### `terraform.tfvars` (Actual Deployed Values)

| Variable | Value |
|---|---|
| `aws_region` | `us-west-2` |
| `project_name` | `8byte` |
| `environment` | `dev` |
| `vpc_cidr` | `10.0.0.0/16` |
| `availability_zones` | `["us-west-2a", "us-west-2b"]` |
| `eks_cluster_name` | `8byte-eks` |
| `eks_version` | `1.35` |
| `eks_node_instance_type` | `t3.medium` |
| `eks_desired_nodes` | `2` |
| `eks_min_nodes` | `1` |
| `eks_max_nodes` | `4` |
| `jenkins_instance_type` | `t3.medium` |
| `jenkins_key_name` | `Atharva-mac` |
| `admin_cidr` | `0.0.0.0/0` ⚠️ (restrict in prod) |
| `rds_engine` | `postgres` |
| `rds_engine_version` | `15.19` |
| `rds_instance_class` | `db.t3.micro` |
| `db_name` | `appdb` |
| `db_username` | `dbadmin` |
| `backup_retention_period` | `7` |

> **Note:** `db_password` is NOT in tfvars. It is generated automatically by Terraform.  
> **Note:** `jenkins_ami_id` is NOT in tfvars. It is fetched from AWS SSM automatically.

---

## 18. Known Simplifications & Production Evolution Path

### Current Simplifications (By Design for Assignment)

| Area | Current (Dev) | Production Standard |
|---|---|---|
| NAT Gateway | Single NAT (cost) | One per AZ |
| RDS Multi-AZ | Disabled | Enabled |
| Jenkins access | Public IP, open `admin_cidr` | Private subnet, SSM Session Manager only |
| Namespaces | Staging/Prod in same EKS cluster | Separate AWS accounts |
| `admin_cidr` | `0.0.0.0/0` | Specific IP range |
| `skip_final_snapshot` | `true` | `false` with unique snapshot names |

### Production Evolution Path

1. **Multi-account structure** — Separate AWS accounts for Dev/Staging/Production with AWS Organizations and SCPs
2. **Private Jenkins** — Move Jenkins to private subnet, access via SSM Session Manager (no public IP, no SSH port open)
3. **Multi-AZ RDS** — Enable `multi_az = true` and set `skip_final_snapshot = false` with timestamped identifiers
4. **Multi-AZ NAT** — One NAT Gateway per AZ for high availability
5. **GitOps-only** — Remove all `kubectl` access from Jenkins entirely, shift fully to Argo CD ApplicationSets
6. **Vault or SSM** — Optionally replace Secrets Manager with HashiCorp Vault for cross-cloud secret sharing
7. **OPA/Kyverno** — Add admission control policies for namespace isolation
8. **ALB with WAF** — Add AWS WAF to the ALB for DDoS and OWASP top 10 protection

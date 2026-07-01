# EKS + RDS Showcase

Production-grade EKS cluster with RDS PostgreSQL backend. Demonstrates infra-as-code maturity: VPC networking, EKS cluster with IRSA, RDS multi-AZ, and a sample app connecting securely to the database.

## SysML Architecture Model

The component structure and function-to-component mapping is documented in the SysML model:

- **SysML BDD**: `company_docs/sysml/eks-workload/eks-workload-architecture.sysml`
- **Function Matrix**: `company_docs/sysml/eks-workload/function-component-matrix.md`

The SysML model documents:
- 20 functional requirements mapped to components
- Interface definitions between AWS and Kubernetes layers
- Data flow from deployment to pod-to-database connection
- Requirement traceability (network isolation, IRSA, Multi-AZ, encryption)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         VPC (10.0.0.0/16)                   │
│  ┌────────────────────────┐  ┌───────────────────────────┐ │
│  │   Public Subnets       │  │    Private Subnets        │ │
│  │   (10.0.1.0/24, /24)   │  │    (10.0.101.0/24, /24)   │ │
│  │                        │  │                           │ │
│  │  ┌──────────────────┐  │  │  ┌─────────────────────┐  │ │
│  │  │  NAT Gateway     │  │  │  │  EKS Nodes (managed)│  │ │
│  │  │  (HA, 1 per AZ)  │  │  │  │  ┌───────────────┐  │  │ │
│  │  └──────────────────┘  │  │  │  │  Sample App    │  │  │ │
│  └────────────────────────┘  │  │  │  (K8s Deploy)  │  │  │ │
│                               │  │  └───────┬───────┘  │  │ │
│  ┌────────────────────────┐  │  │          │           │  │ │
│  │  Internet Gateway      │  │  │  ┌───────▼────────┐  │  │ │
│  └────────────────────────┘  │  │  │  RDS PostgreSQL │  │  │ │
│                               │  │  │  (Multi-AZ)     │  │  │ │
│                               │  │  └─────────────────┘  │  │ │
│                               │  └─────────────────────────┘  │ │
│                               └──────────────────────────────-┘ │
└─────────────────────────────────────────────────────────────┘
```

## What's Included

- **VPC Module**: 3-AZ public/private subnet layout with NAT Gateways
- **EKS Module**: Managed node group, IRSA (IAM Role for ServiceAccount)
- **RDS Module**: PostgreSQL Multi-AZ, encryption at rest, automated backups
- **Security Groups**: Least-privilege networking (only necessary ports)
- **Sample App**: Go app with Kubernetes manifests showing RDS connection

## Quick Start

```bash
# Prerequisites
aws configure
terraform install  # or use terraform in CI

# Clone and init
git clone https://github.com/DurianLAB/eks-rds-showcase.git
cd eks-rds-showcase
terraform init

# Validate
terraform validate

# Plan (preview changes)
terraform plan -var-file=environments/dev.tfvars

# Apply (creates infrastructure)
terraform apply -var-file=environments/dev.tfvars

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name eks-rds-demo

# Deploy sample app
kubectl apply -f k8s-manifests/
```

## IRSA (IAM Role for ServiceAccount)

The EKS cluster uses IRSA to grant the sample app pod an IAM role:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: demo-app
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/eks-rds-demo-app-role
```

This allows the app to:
- Access S3 buckets directly (via IAM policy)
- Connect to RDS using IAM authentication
- No static credentials in pods

## Directory Structure

```
.
├── main.tf                 # Root module composition
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── provider.tf             # AWS provider config
├── versions.tf             # Terraform version constraints
├── modules/
│   ├── vpc/                # VPC with public/private subnets
│   ├── eks/                # EKS cluster + managed node group
│   ├── rds/                # RDS PostgreSQL instance
│   └── security-groups/    # Security group definitions
├── k8s-manifests/          # Sample app + Kubernetes resources
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   └── configmap.yaml
├── environments/
│   ├── ci.tfvars
│   └── prod.tfvars
└── tests/
    └── integration_test.go
```

## Cost Estimate (us-east-1)

| Resource           | Monthly Cost     |
|--------------------|------------------|
| EKS Cluster        | $73.00           |
| EC2 (t3.medium x 2)| ~$30.00          |
| RDS (db.t3.medium) | ~$50.00 (Multi-AZ)|
| NAT Gateway        | ~$32.00          |
| Data transfer      | ~$5.00           |
| **Total**          | **~$190/month**  |

## Security Features

- RDS encryption at rest (AWS-managed KMS key)
- Multi-AZ deployment for HA
- Private subnets for RDS (no public internet access)
- Security groups limiting port 5432 to EKS nodes only
- IRSA eliminates static AWS credentials in pods
- VPC flow logs for network traffic auditing
- EKS cluster logging enabled

## CI/CD with GitHub Actions

```yaml
name: Terraform
on: [push, pull_request]
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform validate
      - run: terraform plan
```

## Next Steps After CKA

This repo demonstrates production EKS patterns. After passing CKA:

1. Deploy this repo to your AWS account
2. Add "EKS hands-on experience" to resume
3. Customize for interviews: explain IRSA, Multi-AZ strategy, network policies

## Author

DurianLAB — Infrastructure as Code showcase

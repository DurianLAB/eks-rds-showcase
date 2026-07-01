variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_endpoints" {
  description = "Custom AWS endpoints for floci local testing"
  type = object({
    ec2        = string
    iam        = string
    eks        = string
    rds        = string
    logs       = string
    cloudwatch = string
    sts        = string
    kms        = string
  })
  default = {
    ec2        = "http://localhost:4566"
    iam        = "http://localhost:4566"
    eks        = "http://localhost:4566"
    rds        = "http://localhost:4566"
    logs       = "http://localhost:4566"
    cloudwatch = "http://localhost:4566"
    sts        = "http://localhost:4566"
    kms        = "http://localhost:4566"
  }
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-rds-demo"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.29"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones (empty = use data source)"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "node_instance_type" {
  description = "EKS node instance type"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "rds_backup_retention" {
  description = "RDS backup retention days"
  type        = number
  default     = 7
}

variable "enable_irsa" {
  description = "Enable IAM Roles for ServiceAccounts"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    Project     = "eks-rds-showcase"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

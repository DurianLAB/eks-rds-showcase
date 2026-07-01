terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  endpoints {
    ec2        = var.aws_endpoints.ec2
    iam        = var.aws_endpoints.iam
    eks        = var.aws_endpoints.eks
    rds        = var.aws_endpoints.rds
    logs       = var.aws_endpoints.logs
    cloudwatch = var.aws_endpoints.cloudwatch
    sts        = var.aws_endpoints.sts
    kms        = var.aws_endpoints.kms
  }

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "test"
  secret_key                  = "test"
}

locals {
  name = "${var.cluster_name}-${var.environment}"
}

data "aws_availability_zones" "available" {
  count = length(var.availability_zones) == 0 ? 1 : 0
  state = "available"
}

locals {
  azs = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available[0].names
}

module "vpc" {
  source = "./modules/vpc"

  cluster_name   = var.cluster_name
  vpc_cidr       = var.vpc_cidr
  availability_zones = local.azs
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  tags           = var.tags
}

module "security_groups" {
  source = "./modules/security-groups"

  cluster_name   = var.cluster_name
  vpc_id         = module.vpc.vpc_id
  eks_sg_name    = "${var.cluster_name}-eks-sg"
  db_sg_name     = "${var.cluster_name}-rds-sg"
  tags           = var.tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  eks_sg_id       = module.security_groups.eks_sg_id
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  enable_irsa        = var.enable_irsa
  tags               = var.tags
}

module "rds" {
  source = "./modules/rds"

  db_name           = var.db_name
  db_instance_class = var.db_instance_class
  db_engine_version = var.db_engine_version
  db_allocated_storage = var.db_allocated_storage
  db_username       = var.db_username
  db_port           = var.db_port
  multi_az          = var.rds_multi_az
  backup_retention  = var.rds_backup_retention
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  db_sg_id          = module.security_groups.rds_sg_id
  tags              = var.tags
}

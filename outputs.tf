output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value      = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value      = module.eks.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value      = module.eks.cluster_arn
}

output "node_role_arn" {
  description = "EKS node IAM role ARN"
  value      = module.eks.node_role_arn
}

output "irsa_role_arn" {
  description = "IRSA role ARN for ServiceAccount"
  value      = module.eks.irsa_role_arn
}

output "db_endpoint" {
  description = "RDS database endpoint"
  value      = module.rds.db_endpoint
}

output "db_port" {
  description = "RDS database port"
  value      = module.rds.db_port
}

output "db_arn" {
  description = "RDS database ARN"
  value      = module.rds.db_arn
}

output "db_name" {
  description = "Database name"
  value      = module.rds.db_name
}

output "vpc_id" {
  description = "VPC ID"
  value      = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value      = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value      = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value      = module.vpc.private_subnet_ids
}

output "eks_security_group_id" {
  description = "EKS security group ID"
  value      = module.security_groups.eks_sg_id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value      = module.security_groups.rds_sg_id
}

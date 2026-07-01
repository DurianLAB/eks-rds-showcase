variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "eks_sg_name" {
  description = "EKS security group name"
  type        = string
}

variable "db_sg_name" {
  description = "RDS security group name"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

resource "aws_security_group" "eks" {
  name        = var.eks_sg_name
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = var.eks_sg_name
  })
}

resource "aws_security_group_rule" "eks_ingress_node" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.eks.id
  description       = "Kubelet API from VPC"
}

resource "aws_security_group_rule" "eks_ingress_api" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks.id
  description       = "EKS API HTTPS from anywhere"
}

resource "aws_security_group_rule" "eks_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks.id
  description       = "Allow all outbound"
}

resource "aws_security_group" "rds" {
  name        = var.db_sg_name
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = var.db_sg_name
  })
}

resource "aws_security_group_rule" "rds_ingress_postgres" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks.id
  security_group_id        = aws_security_group.rds.id
  description              = "PostgreSQL from EKS nodes"
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound"
}

output "eks_sg_id" {
  description = "EKS security group ID"
  value       = aws_security_group.eks.id
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

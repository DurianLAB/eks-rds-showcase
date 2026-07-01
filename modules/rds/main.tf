variable "db_name" {
  description = "Database name"
  type        = string
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
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "multi_az" {
  description = "Enable Multi-AZ"
  type        = bool
  default     = true
}

variable "backup_retention" {
  description = "Backup retention days"
  type        = number
  default     = 7
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for RDS subnets"
  type        = list(string)
}

variable "db_sg_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

resource "aws_db_subnet_group" "main" {
  name       = "rds-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "rds-subnet-group"
  })
}

resource "aws_security_group_rule" "rds_ingress_from_eks" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.db_sg_id
  security_group_id        = var.db_sg_id
  description              = "PostgreSQL from EKS nodes"
}

resource "aws_db_instance" "main" {
  identifier = "eks-rds-demo"

  engine               = "postgres"
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  db_name               = var.db_name
  username              = var.db_username
  password              = "FlociTest123!"
  port                  = var.db_port
  multi_az              = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]

  backup_retention_period   = var.backup_retention
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  auto_minor_version_upgrade = true
  publicly_accessible       = false
  skip_final_snapshot       = true

  storage_encrypted = true

  tags = merge(var.tags, {
    Name = "${var.db_name}-rds"
  })
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "db_arn" {
  description = "RDS ARN"
  value       = aws_db_instance.main.arn
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

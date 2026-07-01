aws_region         = "us-east-1"
cluster_name       = "eks-rds-prod"
environment        = "prod"
cluster_version    = "1.29"
vpc_cidr           = "10.1.0.0/16"

availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnets  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnets = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

node_instance_type = "t3.medium"
node_desired_size  = 3
node_min_size      = 2
node_max_size      = 6

db_instance_class    = "db.t3.medium"
db_engine_version    = "15.4"
db_allocated_storage = 50
db_name              = "appdb"
db_username          = "dbadmin"
db_port              = 5432
rds_multi_az         = true
rds_backup_retention = 7

enable_irsa = true

tags = {
  Project     = "eks-rds-showcase"
  ManagedBy   = "Terraform"
  Environment = "prod"
  Repository  = "github.com/DurianLAB/eks-rds-showcase"
}

aws_region         = "us-east-1"
cluster_name       = "eks-rds-demo"
environment        = "ci"
cluster_version    = "1.29"
vpc_cidr           = "10.0.0.0/16"

availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

node_instance_type = "t3.medium"
node_desired_size  = 2
node_min_size      = 1
node_max_size      = 3

db_instance_class    = "db.t3.medium"
db_engine_version    = "15.4"
db_allocated_storage = 20
db_name              = "appdb"
db_username          = "dbadmin"
db_port              = 5432
rds_multi_az         = false
rds_backup_retention  = 1

enable_irsa = true

tags = {
  Project     = "eks-rds-showcase"
  ManagedBy   = "Terraform"
  Environment = "ci"
  Repository  = "github.com/DurianLAB/eks-rds-showcase"
}

aws_endpoints = {
  ec2        = "http://localhost:4566"
  iam        = "http://localhost:4566"
  eks        = "http://localhost:4566"
  rds        = "http://localhost:4566"
  logs       = "http://localhost:4566"
  cloudwatch = "http://localhost:4566"
  sts        = "http://localhost:4566"
  kms        = "http://localhost:4566"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.region
}

data "aws_availability_zones" "available" {}

locals {
  name = format(var.name, var.environment)

  region = var.region
  azs    = slice(data.aws_availability_zones.available.names, 0, 3)

  vpc_cidr = "10.0.0.0/16"

  db_name = var.db_name
  db_user = var.db_user
  db_port = var.db_port

  tags = {
    Name        = local.name
    Terraform   = "true"
    Environment = var.environment
    Description = var.description
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 20)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 30)]

  map_public_ip_on_launch       = true
  manage_default_security_group = false

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.tags
}

data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = local.name
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from deployment environment"
      cidr_blocks = "0.0.0.0/0"
      # cidr_blocks = "${chomp(data.http.my_ip.response_body)}/32"
    },
  ]
  egress_rules = ["all-all"]

  tags = local.tags
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = local.name

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine                   = "postgres"
  engine_version           = "16"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  family                   = "postgres16" # DB parameter group
  major_engine_version     = "16"         # DB option group
  instance_class           = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name  = local.db_name
  username = local.db_user
  port     = local.db_port

  # Setting manage_master_user_password_rotation to false after it
  # has previously been set to true disables automatic rotation
  # however using an initial value of false (default) does not disable
  # automatic rotation and rotation will be handled by RDS.
  # manage_master_user_password_rotation allows users to configure
  # a non-default schedule and is not meant to disable rotation
  # when initially creating / enabling the password management feature
  manage_master_user_password_rotation              = true
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(15 days)"

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]
  publicly_accessible    = true

  create_cloudwatch_log_group  = false
  backup_retention_period      = 1
  skip_final_snapshot          = true
  deletion_protection          = false
  performance_insights_enabled = false
  create_monitoring_role       = false

  tags = local.tags
}

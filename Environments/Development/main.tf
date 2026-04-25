resource "random_password" "db_password" {
  length  = 16
  special = true

  override_special = "!#$%&*()-_=+[]{}<>:?"

}

module "vpc" {
  source              = "../../Modules/VPC"
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  frontend_subnet_cidr = var.frontend_subnet_cidr
  backend_subnet_cidr = var.backend_subnet_cidr
  database_subnet_cidr = var.database_subnet_cidr
  subnet_az           = var.subnet_az
  environment         = var.environment
  project             = var.project
}

resource "aws_key_pair" "deployer" {
  key_name   = "aws-ec2-key"
  public_key = file("/home/awais/.ssh/aws-ec2-key.pub")
}

module "security_groups" {
  source = "../../Modules/SG"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  project     = var.project
  allowed_IPs = [var.allowed_IPs]
}

module "iam" {
  source = "../../Modules/IAM"

  environment  = var.environment
  project      = var.project
  secrets_arns = ["*"]
}

module "rds" {
  source = "../../Modules/RDS"

  environment = var.environment
  project     = var.project


  subnet_ids             = module.vpc.database_subnet_ids
  vpc_security_group_ids = [module.security_groups.db_sgid]

  username          = var.db_username
  db_name           = var.db_name
  password          = random_password.db_password.result
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention
  skip_final_snapshot     = var.db_skip_final_snapshot
  deletion_protection     = false

  port                = 5432
  availability_zone   = null
  monitoring_interval = 0

}

module "secrets" {
  source = "../../Modules/SECRETS"

  environment = var.environment
  project     = var.project


  db_username             = var.db_username
  db_password             = random_password.db_password.result
  db_engine               = "postgres"
  db_host                 = module.rds.db_instance_address
  db_port                 = module.rds.db_instance_port
  db_name                 = var.db_name
  recovery_window_in_days = 0
}

module "bastian" {
  source = "../../Modules/BASTIAN"

  environment = var.environment
  project     = var.project

  key_name      = aws_key_pair.deployer.key_name
  instance_type = var.instance_type
  subnet_id     = module.vpc.public_subnet_ids[0]

  security_group_id    = module.security_groups.bastion_host_sgid
  iam_instance_profile = module.iam.ec2_instance_profile_name
}

module "external_alb" {
  source = "../../Modules/ALB"

  environment = var.environment
  project     = var.project

  name_prefix = "external"
  internal    = false

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = module.security_groups.externalalb_sgid
  target_group_port  = 3000

  certificate_arn          = ""
  enable_delete_protection = false

}

module "internal_alb" {
  source = "../../Modules/ALB"

  environment = var.environment
  project     = var.project

  name_prefix = "internal"
  internal    = true

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.frontend_subnet_ids
  security_group_ids = module.security_groups.internalalb_sgid
  target_group_port  = 8080

  certificate_arn          = ""
  enable_delete_protection = false

}

module "frontend_asg" {
  source = "../../Modules/ASG"

  environment = var.environment
  region      = var.region
  project     = var.project

  instance_type = var.frontend_instance_type

  target_group_arns    = module.external_alb.target_group_arn
  iam_instance_profile = module.iam.ec2_instance_profile_name
  security_group_id    = module.security_groups.frontend_sgid
  subnet_ids           = module.vpc.frontend_subnet_ids
  min_size             = var.frontend_min_size
  max_size             = var.frontend_max_size
  desired_capacity     = var.frontend_desired_capacity

  docker_image         = var.frontend_docker_image
  dockerhub_password   = var.dockerhub_password
  dockerhub_username   = var.dockerhub_username
  key_name = aws_key_pair.deployer.key_name
  backend_internal_url = "http://${module.internal_alb.alb_dns_name}"

  front_back    = "frontend"
  db_secret_arn = module.secrets.db_secret_arn


}
module "backend_asg" {
  source = "../../Modules/ASG"

  environment = var.environment
  region      = var.region
  project     = var.project

  instance_type        = var.backend_instance_type
  target_group_arns    = module.internal_alb.target_group_arn
  iam_instance_profile = module.iam.ec2_instance_profile_name
  security_group_id    = module.security_groups.backend_sgid
  subnet_ids           = module.vpc.backend_subnet_ids
  min_size             = var.backend_min_size
  max_size             = var.backend_max_size
  desired_capacity     = var.backend_desired_capacity
  docker_image         = var.backend_docker_image
  dockerhub_password   = var.dockerhub_password
  dockerhub_username   = var.dockerhub_username
  key_name = aws_key_pair.deployer.key_name
  backend_internal_url = "http://${module.internal_alb.alb_dns_name}"

  front_back    = "backend"
  db_secret_arn = module.secrets.db_secret_arn
}

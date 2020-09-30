# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  version = "~> 3.4.0"
}
terraform {
  required_version = "~> 0.13.3"
  backend "s3" {}
}



module "vpc" {
  source = "./modules/vpc"
  app_name = var.app_name
  aws_vpc_cidr_block = var.aws_vpc_cidr_block
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  availability_zones = var.availability_zones
}

module "alb" {
  source = "./modules/alb"
  app_name = var.app_name
  aws_sg_alb_ingress_insecure_port = var.aws_sg_alb_ingress_insecure_port
  aws_sg_alb_ingress_secure_port = var.aws_sg_alb_ingress_secure_port
  health_check_path = var.health_check_path
  vpc_id = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets_ids
  public_subnets_ids = module.vpc.public_subnets_ids
}

module "ecr" {
  source = "./modules/ecr"
  app_name = var.app_name
}

module "rds"{
  source = "./modules/rds"
  app_name = var.app_name
  instance_class = var.instance_class
  database_name = var.database_name
  allocated_storage = var.allocated_storage
  vpc_id = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets_ids
  public_subnets_ids = module.vpc.public_subnets_ids
  random_password = module.secrets.random_password
  random_username = module.secrets.random_username
  security_group_ecs_task = module.ecs.security_group_ecs_task
}

module "ecs" {
  source = "./modules/ecs"
  app_name = var.app_name
  container_port = var.container_port
  container_cpu = var.container_cpu
  container_image = var.container_image
  container_memory = var.container_memory
  allocated_storage = var.allocated_storage
  database_name = var.database_name
  vpc_id = module.vpc.vpc_id
  endpoint_rds = module.rds.endpoint_rds
  random_password = module.secrets.random_password
  random_username = module.secrets.random_username
  private_subnets_ids = module.vpc.private_subnets_ids
  aws_alb_target_group = module.alb.aws_alb_target_group
  aws_region = var.aws_region
}

module "secrets" {
  source = "./modules/secrets" 
}
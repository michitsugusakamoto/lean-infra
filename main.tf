terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = "ap-northeast-1"
  #profile = "ctag-sandbox"
  assume_role {
    role_arn = "arn:aws:iam::${local.aws_account_id[local.env]}:role/JuchuHackTerraform"
  }
}

module "ecs" {
    source = "./ecs"

    is_production              = local.env == "prd"
    is_staging_and_staging_off = local.is_staging_and_staging_off

    name               = local.name

    subnets = module.vpc.private_subnet_ids
    ecs_task_sg        = module.sg.ecs_task_sg
    target_group_api   = module.lb.target_group_api
    target_group_ui   = module.lb.target_group_ui

    db_host = module.rds.rds_endpoint
    db_user = local.db_user
    db_pass = local.db_password
    db_name = local.db_name
}

module "vpc" {
    source = "./vpc"

    name                 = local.name
    cidr_block           = local.vpc_cidr
    public_subnet_cidrs  = [   "10.0.0.0/24",   "10.0.1.0/24",   "10.0.2.0/24"]
    private_subnet_cidrs = [ "10.0.128.0/24", "10.0.129.0/24", "10.0.130.0/24"]
    subnet_azs           = local.availability_zones

    vpc_endpoint_sg      = module.sg.vpc_endpoint_sg
}

module "sg" {
    source = "./sg"
    
    name     = local.name
    vpc_id   = module.vpc.vpc_id
    vpc_cidr = local.vpc_cidr
}

module "lb" {
    source  = "./lb"

    name                = local.name
    public_subnet_ids   = module.vpc.public_subnet_ids
    alb_security_groups = [module.sg.alb_sg]

    vpc_id              = module.vpc.vpc_id
    domain              = local.domain
}

module "iam" {
  source = "./iam"

  env                = local.env
  name               = local.name
  aws_account_id_prd = local.aws_account_id.prd
  aws_account_id     = local.aws_account_id[local.env]
}

module "route53" {
    source = "./route53"

    domain       = local.domain
    alb_dns_name = module.lb.dns_name
    alb_zone_id  = module.lb.zone_id
}

module "rds" {
  source = "./rds"

  is_production              = local.env == "prd"
  is_staging_and_staging_off = local.is_staging_and_staging_off
  
  name               = local.name
  rds_sg             = module.sg.rds_sg
  private_subnet_ids = module.vpc.private_subnet_ids
  // インスタンスクラスを変更する場合は
  // alert/main.tfのaurora-freeable-memory, aurora-free-locale-strageの閾値を変更する必要がある
  instance_class     = "db.t3.medium"
  #instance_class     = "db.t3.small"
  availability_zones = local.availability_zones
  db_name            = local.db_name
  db_user            = local.db_user
  db_password        = local.db_password
}
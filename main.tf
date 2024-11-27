
# main.tf
provider "aws" {
  region = "ap-northeast-2"
}

module "security_groups" {
  source       = "./modules/security_groups"
  vpc_id       = var.vpc_id
  project_name = var.project_name
}

module "master" {
  source                 = "./master"
  ami_id                 = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnets[0]
  project_name           = var.project_name
  vpc_security_group_ids = [module.security_groups.master_sg_id]
}

module "worker" {
  source                 = "./worker"
  ami_id                 = var.ami_id
  instance_type          = var.instance_type
  subnets                = var.subnets
  project_name           = var.project_name
  vpc_security_group_ids = [module.security_groups.worker_sg_id]
}
terraform {
  required_version = ">= 1.3"
  required_providers {
    aws        = { source = "hashicorp/aws"; version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes"; version = "~> 2.23" }
    helm       = { source = "hashicorp/helm"; version = "~> 2.12" }
  }

  backend "s3" {
    bucket = "pratik-terraform-state"
    key    = "eks-prod/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = "ap-south-1"
}

locals {
  cluster_name = "pratik-prod"
  common_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Owner       = "pratik"
  }
}

module "vpc" {
  source             = "../../modules/vpc"
  cluster_name       = local.cluster_name
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  common_tags        = local.common_tags
}

module "iam" {
  source       = "../../modules/iam"
  cluster_name = local.cluster_name
  common_tags  = local.common_tags
}

module "eks" {
  source                = "../../modules/eks"
  cluster_name          = local.cluster_name
  kubernetes_version    = "1.29"
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  cluster_role_arn      = module.iam.cluster_role_arn
  node_role_arn         = module.iam.node_role_arn
  ebs_csi_role_arn      = module.iam.ebs_csi_role_arn
  app_node_instance_types = ["t3.large"]
  app_node_desired      = 3
  app_node_min          = 2
  app_node_max          = 10
  common_tags           = local.common_tags
}

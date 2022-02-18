provider "aws" {
  region = var.region
}

locals {
  name            = "${var.name}-${replace(basename(path.cwd), "_", "-")}"
  cluster_version = "1.21"

  tags = {
    Example    = local.name
    GithubRepo = "hcp_consul"
    GithubOrg  = "ppresto"
  }
}

#
### EKS Module
#
# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.4.1"
  cluster_name                          = local.name
  cluster_version                       = local.cluster_version
  cluster_endpoint_private_access       = true
  cluster_endpoint_public_access        = true
  cluster_additional_security_group_ids = [data.terraform_remote_state.aws_network.outputs.consul_server_sg_id]
  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  vpc_id     = data.terraform_remote_state.aws_network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.aws_network.outputs.vpc_private_subnets

  enable_irsa = true

  node_groups = {
    application = {
      name_prefix      = "hashicups"
      instance_types   = ["t3a.medium"]
      desired_capacity = 3
      max_capacity     = 3
      min_capacity     = 3
    }
  }

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
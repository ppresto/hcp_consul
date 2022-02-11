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

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_additional_security_group_ids = [data.terraform_remote_state.aws_network.outputs.consul_server_sg_id]
  cluster_addons = {
    # Note: https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  vpc_id     = data.terraform_remote_state.aws_network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.aws_network.outputs.vpc_private_subnets

  enable_irsa = true

  # You require a node group to schedule coredns which is critical for running correctly internal DNS.
  # If you want to use only fargate you must follow docs `(Optional) Update CoreDNS`
  # available under https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html
  eks_managed_node_groups = {
    example = {
      desired_size = 1

      instance_types = ["t3.large"]
      labels = {
        Example    = "managed_node_groups"
        GithubRepo = "hcp_consul"
        GithubOrg  = "ppresto"
      }
      tags = {
        ExtraTag = "example"
      }
    }
  }

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "backend"
          labels = {
            Application = "backend"
          }
        },
        {
          namespace = "default"
          labels = {
            WorkerType = "fargate"
          }
        }
      ]

      tags = {
        Owner = "default"
      }

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }

    secondary = {
      name = "secondary"
      selectors = [
        {
          namespace = "default"
          labels = {
            Environment = "dev"
            GithubRepo  = "hcp_consul"
            GithubOrg   = "ppresto"
          }
        }
      ]

      # Using specific subnets instead of the subnets supplied for the cluster itself
      #subnet_ids = [module.vpc.private_subnets[1]]

      tags = {
        Owner = "secondary"
      }
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
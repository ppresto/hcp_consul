terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.72"
    }
  }
}

provider "kubernetes" {
  host                    = data.aws_eks_cluster.cluster.endpoint
  token                   = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate  = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  load_config_file        = false
}
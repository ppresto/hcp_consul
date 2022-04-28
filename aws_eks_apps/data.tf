data "terraform_remote_state" "hcp_consul" {
  backend = "remote"
  config = {
    organization = "presto-projects"
    workspaces = {
      name = "hcp_consul"
    }
  }
}

data "terraform_remote_state" "aws_eks" {
  backend = "remote"
  config = {
    organization = "presto-projects"
    workspaces = {
      name = "aws_eks"
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.aws_eks.outputs.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.aws_eks.outputs.cluster_id
}
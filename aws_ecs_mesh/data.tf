data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "this" {}

data "aws_caller_identity" "current" {}

data "aws_security_group" "vpc_default" {
  name   = "default"
  vpc_id = local.vpc_id
}

data "terraform_remote_state" "hcp_consul" {
  backend = "remote"
  config = {
    organization = "presto-projects"
    workspaces = {
      name = "hcp_consul"
    }
  }
}
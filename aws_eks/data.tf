data "terraform_remote_state" "aws_network" {
  backend = "remote"
  config = {
    organization = "presto-projects"
    workspaces = {
      name = "aws_network"
    }
  }
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
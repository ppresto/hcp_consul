data "terraform_remote_state" "aws_network" {
  backend = "remote"
  config = {
    organization = "presto-projects"
    workspaces = {
      name = "aws_network"
    }
  }
}
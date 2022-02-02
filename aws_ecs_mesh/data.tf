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
  vpc_id = var.vpc_id
}

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


locals {
  example_server_app_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "app"
    }
  }

  example_client_app_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "client"
    }
  }
  private_subnet_ids = data.terraform_remote_state.aws_network.vpc_private_subnets
  public_subnet_ids = data.terraform_remote_state.aws_network.vpc_public_subnets

  consul_config_file = jsonencode(data.terraform_remote_state.hcp_consul.consul_config_file)
  consul_gossip_key = local.consul_config_file.encrypt
  consul_server_http_addr = data.terraform_remote_state.hcp_consul.consul_private_endpoint_url
  consul_datacenter = data.terraform_remote_state.hcp_consul.datacenter
  consul_acl_token = data.terraform_remote_state.hcp_consul.consul_root_token_secret_id

  consul_client_ca_path = data.terraform_remote_state.hcp_consul.consul_ca_file
}
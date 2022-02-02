variable "name" {
  description = "Name to be used on all the resources as identifier."
  type        = string
  default     = "consul-ecs"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}

variable "user_public_ip" {
  description = "Your Public IP. This is used in the load balancer security groups to ensure only you can access the Consul UI and example application."
  type        = string
  default     = "52.119.127.230"
}

variable "default_tags" {
  description = "Default Tags for AWS"
  type        = map(string)
  default = {
    Environment = "dev"
    Team        = "Education-Consul"
    tutorial    = "Serverless Consul service mesh with ECS and HCP"
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
  vpc_id = data.terraform_remote_state.aws_network.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.aws_network.outputs.vpc_private_subnets
  public_subnet_ids = data.terraform_remote_state.aws_network.outputs.vpc_public_subnets

  consul_config_file = jsonencode(data.terraform_remote_state.hcp_consul.outputs.consul_config_file)
  consul_gossip_key = local.consul_config_file.encrypt
  consul_server_http_addr = data.terraform_remote_state.hcp_consul.outputs.consul_private_endpoint_url
  consul_datacenter = data.terraform_remote_state.hcp_consul.outputs.datacenter
  consul_acl_token = data.terraform_remote_state.hcp_consul.outputs.consul_root_token_secret_id

  consul_client_ca_path = data.terraform_remote_state.hcp_consul.outputs.consul_ca_file
}
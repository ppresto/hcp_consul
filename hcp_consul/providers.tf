terraform {
  required_version = ">= 1.1.4"

  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.22"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.74.1"
    }
  }
}

provider "consul" {
  address    = hcp_consul_cluster.example_hcp.consul_public_endpoint_url
  datacenter = hcp_consul_cluster.example_hcp.datacenter
}
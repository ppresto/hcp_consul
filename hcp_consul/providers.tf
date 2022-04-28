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
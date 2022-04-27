provider "tfe" {
  hostname = var.tfe_hostname
  token    = var.tfe_token
}

terraform {
  required_version = ">= 0.13.06"
  required_providers {
    tfe = {
      version = "~>0.25"
    }
    multispace = {
      source = "mitchellh/multispace"
      version = "~>0.1.1"
    }
  }
}


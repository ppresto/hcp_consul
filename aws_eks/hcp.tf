
#
### Configure Consul Secrets
#
resource "kubernetes_secret" "consul-ca-cert" {
  metadata {
    name = "consul-ca-cert"
  }

  data = {
    consul-ca-cert = data.terraform_remote_state.hcp_consul.outputs.consul_ca_file
  }
}

resource "kubernetes_secret" "consul-gossip-key" {
  metadata {
    name = "consul-gossip-key"
  }

  data = {
    consul-gossip-key = local.consul_config_file.encrypt
  }
}

resource "kubernetes_secret" "consul-bootstrap-token" {
  metadata {
    name = "consul-bootstrap-token"
  }

  data = {
    consul-bootstrap-token = local.consul_acl_token
  }
}

#
### Install Consul Client Agents into EKS using helm
#

data "template_file" "agent_config" {
  template = file("${path.module}/config.yaml")
  vars = {
    DATACENTER     = local.consul_datacenter
    RETRY_JOIN = local.consul_retry_join
    KUBE_API_URL   = local.consul_server_http_addr
  }
}

resource "helm_release" "consul" {
  name       = "consul"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "hashicorp/consul"
  version    = "0.39.0"

  values = [data.template_file.agent_config.rendered]

  set {
    name  = "global.image"
    #value = "hashicorp/consul-enterprise:1.11.0-ent"
    value = "hashicorp/consul:1.11.2"
  }
}
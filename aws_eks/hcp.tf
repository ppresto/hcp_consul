
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

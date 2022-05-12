#
### Configure Consul Secrets
#
resource "kubernetes_secret" "consul-ca-cert" {
  metadata {
    name = "consul-ca-cert"
    namespace = var.namespace
  }
  data = {
    "tls.crt" = base64decode(data.terraform_remote_state.hcp_consul.outputs.consul_ca_file)
  }
}

resource "kubernetes_secret" "consul-gossip-key" {
  metadata {
    name = "consul-gossip-key"
    namespace = var.namespace
  }
  data = {
    "key" = local.consul_config_file.encrypt
  }
}

resource "kubernetes_secret" "consul-bootstrap-token" {
  metadata {
    name = "consul-bootstrap-token"
    namespace = var.namespace
  }
  data = {
    "token" = local.consul_acl_token
  }
}
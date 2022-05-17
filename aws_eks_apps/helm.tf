#
### Install Consul Client Agents into EKS using helm
#

data "template_file" "agent_config" {
  template = file("${path.module}/templates/${var.consul_template}/helm/helm-config.yaml")
  vars = {
    DATACENTER   = local.consul_datacenter
    RETRY_JOIN   = jsonencode(local.consul_retry_join)
    KUBE_API_URL = data.terraform_remote_state.aws-eks.outputs.cluster_endpoint
  }
}

resource "helm_release" "consul" {
  name = "consul"
  namespace = var.namespace
  create_namespace = true
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  version = "0.33.0"

  values = [data.template_file.agent_config.rendered]
  set {
    name  = "global.image"
    value = "hashicorp/consul-enterprise:1.11.0-ent"
    #value = "hashicorp/consul:1.10.1"
  }
}

#
### Namespace
#
data "kubernetes_all_namespaces" "allns" {}
resource "kubernetes_namespace" "example" {
  count = contains(data.kubernetes_all_namespaces.allns.namespaces, var.namespace) ? 0 : 1
  metadata {
    labels = {
      service = "consul"
    }
    name = "consul"
  }
}
#
### Configure Consul Secrets for the Helm Chart
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
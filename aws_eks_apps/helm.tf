#
### Install Consul Client Agents into EKS using helm
#

data "template_file" "agent_config" {
  template = file("${path.module}/templates/helm-config.yaml")
  vars = {
    DATACENTER   = local.consul_datacenter
    RETRY_JOIN   = jsonencode(local.consul_retry_join)
    KUBE_API_URL = data.terraform_remote_state.aws-eks.outputs.cluster_endpoint
  }
}

resource "helm_release" "consul" {
  name = "consul"
  namespace = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  /*
  version = "0.32.1" - Causes connect-inject 403 (Permission denied)
    $  kubectl logs frontend-5d8bbf496-ql26d consul-connect-inject-init
    2022-02-17T21:40:04.732Z [INFO]  Consul login complete
    2022-02-17T21:40:04.735Z [INFO]  Registered service has been detected: service=frontend
    2022-02-17T21:40:04.735Z [INFO]  Registered service has been detected: service=frontend-sidecar-proxy
    2022-02-17T21:40:04.736Z [INFO]  Connect initialization completed
    ==> Failed to create configuration to apply traffic redirection rules: failed to fetch proxy service from Consul Agent: Unexpected response code: 403 (Permission denied)
  Fix: version = 0.33.0
  */
  version = "0.33.0"

  values = [data.template_file.agent_config.rendered]

  set {
    name  = "global.image"
    value = "hashicorp/consul-enterprise:1.11.0-ent"
    #value = "hashicorp/consul:1.10.1"
  }
}
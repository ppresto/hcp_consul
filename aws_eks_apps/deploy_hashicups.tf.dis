data "kubectl_path_documents" "manifests" {
  pattern = "${path.module}/hashicups/*.yaml"
}

resource "kubectl_manifest" "applications" {
  for_each   = toset(data.kubectl_path_documents.manifests.documents)
  yaml_body  = each.value
  depends_on = [helm_release.consul]
}

data "kubernetes_service" "ingress" {
  metadata {
    name = "consul-ingress-gateway"
  }
  depends_on = [kubectl_manifest.applications]
}
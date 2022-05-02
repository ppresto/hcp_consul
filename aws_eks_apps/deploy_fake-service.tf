data "kubectl_path_documents" "fake-service-yaml" {
  pattern = "${path.module}/fake-service-jaeger/*.yaml"
}

resource "kubectl_manifest" "fake-service" {
  for_each   = toset(data.kubectl_path_documents.fake-service-yaml.documents)
  yaml_body  = each.value
  depends_on = [helm_release.consul]
}

data "kubernetes_service" "ingress" {
  metadata {
    name = "consul-ingress-gateway"
  }
  depends_on = [kubectl_manifest.fake-service]
}
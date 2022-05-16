data "kubectl_path_documents" "fake-service-yaml" {
  pattern = "${path.module}/templates/fs-tp/*.yaml"
}
data "kubectl_path_documents" "fs-init" {
  pattern = "${path.module}/templates/fs-tp/init-consul-config/*.yaml"
}

resource "kubectl_manifest" "fs-init" {
  for_each   = toset(data.kubectl_path_documents.fs-init.documents)
  yaml_body  = each.value
  depends_on = [helm_release.consul]
}
resource "kubectl_manifest" "fake-service" {
  for_each   = toset(data.kubectl_path_documents.fake-service-yaml.documents)
  yaml_body  = each.value
  depends_on = [kubectl_manifest.fs-init]
}

data "kubernetes_service" "ingress" {
  metadata {
    name = "consul-ingress-gateway"
    namespace = var.namespace
  }
  depends_on = [kubectl_manifest.fs-init]
}
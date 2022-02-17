data "kubectl_path_documents" "manifests" {
  pattern = "${path.module}/hashicups/*.yaml"
}

resource "kubectl_manifest" "applications" {
  # count     = length(data.kubectl_path_documents.manifests.documents)
  # For some reason using the above line returns a count not known until apply
  # error, even though the files are static. This needs to be kept in sync with
  # the YAML files defined in the hashicups/ directory.
  count     = 4
  yaml_body = element(data.kubectl_path_documents.manifests.documents, count.index)
}

data "kubernetes_service" "ingress" {
  metadata {
    name = "consul-ingress-gateway"
  }

  depends_on = [kubectl_manifest.applications]
}
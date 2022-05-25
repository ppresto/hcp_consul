data "kubectl_path_documents" "coredns-patch" {
  pattern = "${path.module}/templates/*.yaml"
}

resource "kubectl_manifest" "coredns-patch" {
  for_each   = toset(data.kubectl_path_documents.coredns-patch.documents)
  yaml_body  = each.value
  depends_on = [module.eks]
}
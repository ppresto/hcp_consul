data "kubectl_file_documents" "ingress_gw" {
    content = file("${path.module}/templates/ingress-gateway.yaml")
}

resource "kubectl_manifest" "reg_ingress_gw" {
    for_each  = data.kubectl_file_documents.ingress_gw.manifests
    yaml_body = each.value
}
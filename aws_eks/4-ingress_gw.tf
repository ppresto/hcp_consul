data "kubectl_file_documents" "ingress_gw" {
    content = file("${path.module}/templates/ingress-gateway.yaml")
}
data "kubectl_file_documents" "svc_intensions" {
    content = file("${path.module}/templates/service-intentions.yaml")
}

resource "kubectl_manifest" "apply_ingress_gw" {
    for_each  = data.kubectl_file_documents.ingress_gw.manifests
    yaml_body = each.value
}
resource "kubectl_manifest" "apply_svc_intensions" {
    for_each  = data.kubectl_file_documents.svc_intensions.manifests
    yaml_body = each.value
}
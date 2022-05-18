data "kubectl_path_documents" "fake-service" {
  pattern = "${path.module}/../aws_eks/apps/templates/${var.consul_template}/*.yaml"
}

resource "kubectl_manifest" "fake-service" {
  for_each   = toset(data.kubectl_path_documents.fake-service.documents)
  yaml_body  = each.value
  depends_on = [module.eks]
}
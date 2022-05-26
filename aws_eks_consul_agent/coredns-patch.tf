data "template_file" "coredns_configmap_patch" {
  template = file("${path.module}/templates/coredns/coredns-patch.yaml")
  vars = {
    CONSUL_DNS_CLUSTER_IP = var.consul_dns_cluster_ip
  }
}

data "kubectl_path_documents" "coredns-patch" {
  pattern = "[data.template_file.coredns_configmap_patch.rendered]"
}

# Get consul dns server IP
resource "kubectl_manifest" "coredns-patch" {
  for_each   = toset(data.kubectl_path_documents.coredns-patch.documents)
  yaml_body  = each.value
  depends_on = [helm_release.consul]
}
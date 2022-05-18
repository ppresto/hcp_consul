#
### Create K8s Namespace if it doesn't exist
#
data "kubernetes_all_namespaces" "allns" {}

resource "kubernetes_namespace" "create" {
  count = contains(data.kubernetes_all_namespaces.allns.namespaces, "consul") ? 0 : 1
  metadata {
    labels = {
      service = "consul"
    }
    name = "consul"
  }
}
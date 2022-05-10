# Configure Consul
resource "consul_namespace" "app-api" {
  name        = "api"
  description = "API App Team"

  meta = {
    foo = "bar"
  }
}

resource "consul_admin_partition" "qa" {
  name        = "qa"
  description = "Partition for QA Environment"
}


# Configure Consul
resource "consul_admin_partition" "qa" {
  name        = "qa"
  description = "Partition for QA Environment"
}

resource "consul_namespace" "default-app-api" {
  name        = "api"
  description = "API App Team"

  meta = {
    foo = "bar"
  }
}

resource "consul_namespace" "qa-app-api" {
  name        = "api"
  description = "API App Team"
  partition   = consul_admin_partition.qa.name

  meta = {
    foo = "bar"
  }
}
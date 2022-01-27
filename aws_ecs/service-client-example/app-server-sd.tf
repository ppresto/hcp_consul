resource "aws_service_discovery_private_dns_namespace" "server" {
  name        = "presto.local"
  description = "server"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "server" {
  name = "fake-server"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.server.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 5
  }
}
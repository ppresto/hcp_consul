output "client_lb_address" {
  value = "http://${aws_lb.example_client_app.dns_name}:9090/ui"
}

output "gossip_key" {
  value = local.consul_gossip_key
}

output "consul_server_private_endpoint" {
  value = substr(local.consul_server_http_addr, 8, -1)
}
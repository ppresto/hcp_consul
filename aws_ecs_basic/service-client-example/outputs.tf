output "client_lb_address" {
  value = "http://${aws_lb.example_client_app.dns_name}:9090/ui"
}

output "fake_server" {
  value = "${var.dns_namespace}.${var.dns_fake_server}:9090"
}
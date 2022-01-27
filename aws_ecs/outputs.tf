# fake-service outputs
output "client_lb_address" {
  value = module.fake-service.client_lb_address
}

output "fake_server_sd_route53" {
  value = module.fake-service.fake_server
}
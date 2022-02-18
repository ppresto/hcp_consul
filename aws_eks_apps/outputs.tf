output "consul_retry_join" {
  value = local.consul_retry_join
}

output "consul_config_yaml" {
  value = data.template_file.agent_config.rendered
}
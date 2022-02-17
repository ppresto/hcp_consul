resource "aws_security_group" "consul_server" {
  name_prefix = "${var.region}-consul-server-sg"
  description = "Firewall for the consul server."
  vpc_id      = module.vpc.vpc_id
  tags = merge(
    { "Name" = "${var.region}-consul-server-sg" },
    { "Project" = var.region },
    { "Owner" = "presto" }
  )
}

#
###  Ingress Rules 
#
resource "aws_security_group_rule" "consul_server_allow_server_8301" {
  security_group_id = aws_security_group.consul_server.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "Used to handle gossip from server"
}
resource "aws_security_group_rule" "consul_server_allow_server_8301_udp" {
  security_group_id = aws_security_group.consul_server.id
  type              = "ingress"
  protocol          = "udp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "Used to handle gossip from server"
}


resource "aws_security_group_rule" "consul_server_allow_client_8301" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8301
  to_port                  = 8301
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}
resource "aws_security_group_rule" "consul_server_allow_client_8301_udp" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "udp"
  from_port                = 8301
  to_port                  = 8301
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}

# Bastion SSH access
resource "aws_security_group_rule" "consul_server_allow_22_bastion" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
  source_security_group_id = aws_security_group.bastion.id
  description              = "Allow SSH traffic from consul bastion."
}

#EKS - Consul ingress gateway
# kubectl logs consul-ingress-gateway-55d874f58-rc98s service-init
# Error registering service "ingress-gateway": Put "https://10.20.3.197:8501/v1/agent/service/register": dial tcp 10.20.3.197:8501: connect: connection refused
resource "aws_security_group_rule" "consul_server_allow_client_8501" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8501
  to_port                  = 8501
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}
# EKS - Consul client
# [ERROR] agent.auto_config: AutoEncrypt.Sign RPC failed: addr=172.25.26.99:8300 error="rpcinsecure error establishing connection: dial tcp <nil>->172.25.26.99:8300: i/o timeout"
resource "aws_security_group_rule" "consul_server_allow_client_8300" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8300
  to_port                  = 8300
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}
resource "aws_security_group_rule" "consul_server_allow_client_8300_udp" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "udp"
  from_port                = 8300
  to_port                  = 8300
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle gossip between client agents"
}

# EKS - API needs access to Pods
# Error from server (InternalError): error when creating "hashicups/frontend.yaml": Internal error occurred: failed calling webhook "mutate-servicedefaults.consul.hashicorp.com": 
#   Post "https://consul-controller-webhook.default.svc:443/mutate-v1alpha1-servicedefaults?timeout=10s": context deadline exceeded
resource "aws_security_group_rule" "consul_client_allow_eksapi_9443" {
  security_group_id        = aws_security_group.consul_server.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9443
  to_port                  = 9443
  source_security_group_id = aws_security_group.consul_server.id
  description              = "Used to handle EKS API request to Pods"
}

#
### Egress Rules
#
resource "aws_security_group_rule" "hcp_tcp_RPC_from_clients" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 8300
  to_port           = 8300
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "For RPC communication between clients and servers"
}
resource "aws_security_group_rule" "hcp_tcp_server_gossip" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "Server to server gossip communication"
}
resource "aws_security_group_rule" "hcp_udp_server_gossip" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "udp"
  from_port         = 8301
  to_port           = 8301
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "Server to server gossip communication"
}
resource "aws_security_group_rule" "hcp_tcp_http" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "The HTTP API"
}
resource "aws_security_group_rule" "hcp_tcp_https" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block]
  description       = "The HTTPS API"
}
resource "aws_security_group_rule" "consul_server_allow_outbound" {
  security_group_id = aws_security_group.consul_server.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow any outbound traffic."
}
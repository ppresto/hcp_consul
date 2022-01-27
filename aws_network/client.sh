#!/bin/bash

CONFIG_FILE_64="${CONSUL_CONFIG_FILE}"
CONSUL_CA=$(echo ${CONSUL_CA_FILE}| base64 -d)

# Install Consul
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update && apt install -y consul unzip jq

# Set variables with jq
GOSSIP_KEY=$(echo $CONFIG_FILE_64 | base64 -d | jq -r '.encrypt')
RETRY_JOIN=$(echo $CONFIG_FILE_64 | base64 -d | jq -r '.retry_join[]')
DATACENTER=$(echo $CONFIG_FILE_64 | base64 -d | jq -r '.datacenter')

# Grab instance IP
local_ip=`ip -o route get to 169.254.169.254 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`

# Setup Consul Client for HCP
mkdir -p /opt/consul
mkdir -p /etc/consul.d/certs

touch /etc/consul.d/consul.env  #placeholder for env vars

cat > /etc/consul.d/certs/ca.pem <<- EOF
$CONSUL_CA
EOF

# Modify the default consul.hcl file
cat > /etc/consul.d/consul.hcl <<- EOF
datacenter = "$DATACENTER"
data_dir = "/opt/consul"
server = false
#client_addr = "0.0.0.0"
#bind_addr = "0.0.0.0"
#advertise_addr = "$local_ip"
retry_join = ["$RETRY_JOIN"]
encrypt = "$GOSSIP_KEY"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true
log_level = "INFO"
ui = true
#verify_incoming = true
#verify_outgoing = true
#verify_server_hostname = true
ca_file = "/etc/consul.d/certs/ca.pem"
#cert_file = "/etc/consul.d/certs/client-cert.pem"
#key_file = "/etc/consul.d/certs/client-key.pem"
auto_encrypt = {
  tls = true
}

#ports {
#  grpc = 8502
#}
EOF

cat >/etc/consul.d/client_acl.hcl <<- EOF
acl = {
  #enabled = true
  #down_policy = "async-cache"
  #default_policy = "deny"
  #enable_token_persistence = true
  tokens {
    agent = "${CONSUL_ACL_TOKEN}"
  }
}
EOF

# Configure systemd
cat >/etc/systemd/system/consul.service <<- EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
EnvironmentFile=-/etc/consul.d/consul.env
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
systemctl enable consul
systemctl start consul

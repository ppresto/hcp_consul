#!/bin/bash

# stored in: /var/lib/cloud/instances/instance-id/user-data.txt
# logged at: /var/log/cloud-init-output.log

CONFIG_FILE_64="${CONSUL_CONFIG_FILE}"
CONSUL_CA=$(echo ${CONSUL_CA_FILE}| base64 -d)

#
### Install Consul
#
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update && apt install -y consul-enterprise=1.12.0-1+ent unzip jq

#
### Install Envoy
#
curl https://func-e.io/install.sh | bash -s -- -b /usr/local/bin/
func-e versions -all
func-e use 1.20.2
cp /root/.func-e/versions/1.20.2/bin/envoy /usr/local/bin
envoy --version

#
### Install Docker, docker-compose
#
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

#
### Install fake-service
#
mkdir -p /opt/consul/fake-service/central_config
cd /opt/consul/fake-service
wget https://github.com/nicholasjackson/fake-service/releases/download/v0.23.1/fake_service_linux_amd64.zip
unzip fake_service_linux_amd64.zip
chmod 755 /opt/consul/fake-service/fake-service

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
client_addr = "0.0.0.0"
bind_addr = "0.0.0.0"
advertise_addr = "$local_ip"
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

connect {
  enabled = true
}

ports {
  grpc = 8502
}
EOF

cat >/etc/consul.d/client_acl.hcl <<- EOF
acl = {
  enabled = true
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
Description="HashiCorp Consul Ent - A service mesh solution"
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

# Configure fake-service (api)
cat >/opt/consul/fake-service/service_api.hcl <<- EOF
{
  "service": {
    "name": "api",
    "namespace": "default",
    "id": "api",
    "port": 9091,
    "token": "${SERVICE_ACL_TOKEN}",
    "tags": ["vm","v1"],
    "meta": {
      "version": "v1"
    },
    "check": {
      "http": "http://localhost:9091/health",
      "method": "GET",
      "interval": "1s",
      "timeout": "1s"
    },
    "connect": {
      "sidecar_service": {
	      "port": 20000
       }
    }
  }
}
EOF

cat >/opt/consul/fake-service/central_config/service_intentions.hcl <<- EOF
Kind = "service-intentions"
Name = "api"
Sources = [
  {
    Name   = "web"
    Action = "allow"
  }
]
EOF

cat >/opt/consul/fake-service/central_config/service_defaults.hcl <<- EOF
Kind = "service-defaults"
Name = "api"
Protocol = "http"
EOF

cat >/opt/consul/fake-service/central_config/traffic-resolver.hcl <<- EOF
Kind          = "service-resolver"
Name          = "api"
DefaultSubset = "v1"
Subsets = {
  v1 = {
    Filter = "Service.Meta.version == v1"
  }
  v2 = {
    Filter = "Service.Meta.version == v2"
  }
}
EOF

cat >/opt/consul/fake-service/central_config/traffic-splitter.hcl <<- EOF
Kind = "service-splitter"
Name = "api"
Splits = [
  {
    Weight        = 100
    ServiceSubset = "v1"
  },
  {
    Weight        = 0
    ServiceSubset = "v2"
  },
]
EOF

cat >/opt/consul/fake-service/start.sh <<- EOF
#!/bin/bash

export CONSUL_HTTP_TOKEN="${CONSUL_ACL_TOKEN}"
sleep 1
consul services register ./service_api.hcl

sleep 1
consul config write ./central_config/service_intentions.hcl
consul config write ./central_config/service_defaults.hcl
consul config write ./central_config/traffic-resolver.hcl
consul config write ./central_config/traffic-splitter.hcl

# Start API Service
export MESSAGE="API RESPONSE"
export NAME="api-v1"
export SERVER_TYPE="http"
export LISTEN_ADDR="127.0.0.1:9091"
nohup ./fake-service &

sleep 1
consul connect envoy -sidecar-for api -admin-bind localhost:19000 > api-proxy.log &
EOF

cat >/opt/consul/fake-service/stop.sh <<- EOF
#!/bin/bash
consul config delete -kind service-intentions -name api
consul config delete -kind service-defaults -name api
consul config delete -kind service-resolver -name api
consul config delete -kind service-splitter -name api
consul services deregister ./service_api.hcl
pkill envoy
pkill fake-service
EOF

# Update user profiles for Consul CLI use
echo "export CONSUL_HTTP_TOKEN=${CONSUL_ACL_TOKEN}" >> /root/.profile
echo "export CONSUL_HTTP_TOKEN=${CONSUL_ACL_TOKEN}" >> /home/ubuntu/.profile
# Start Consul
systemctl enable consul.service
systemctl start consul.service

# Start fake-service container using docker-compose
cd /opt/consul/fake-service
chmod 755 *.sh
./start.sh

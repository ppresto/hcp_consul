#!/bin/bash

#
### Install Envoy
#
curl https://func-e.io/install.sh | bash -s -- -b /usr/local/bin
func-e versions -all
func-e use 1.20.2
cp $${HOME}/.func-e/versions/1.20.2/bin/envoy /usr/local/bin
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

# Install fake-service (api)
mkdir -p /opt/consul/fake-service/central_config
mkdir /opt/consul/fake-service/service_config

cat >/opt/consul/fake-service/service_config/api_vi.hcl <<- EOF
service {
  name = "api"
  id = "api-v1"
  port = 9090
  
  connect { 
    sidecar_service {
      port = 20000
      
      check {
        name = "Connect Envoy Sidecar"
        tcp = "localhost:20000"
        interval ="10s"
      }

      proxy {
      }
    }  
  }
}
EOF


cat >/opt/consul/fake-service/central_config/api_defaults.hcl <<- EOF
Kind = "service-defaults"
Name = "api"

Protocol = "grpc"
EOF

cat >/opt/consul/fake-service/docker-compose.yml <<- EOF
---
version: "3.3"
services:
  api:
    image: nicholasjackson/fake-service:v0.21.0
    container_name: api
    environment:
      LISTEN_ADDR: 0.0.0.0:9090
      MESSAGE: "API response"
      NAME: "API"
      SERVER_TYPE: "grpc"
  api_proxy:
    image: nicholasjackson/consul-envoy:v1.6.0-v0.10.0
    container_name: api_proxy
    depends_on:
      - "api"
    environment:
      CONSUL_HTTP_ADDR: 172.17.0.1:8500
      CONSUL_GRPC_ADDR: 172.17.0.1:8502
      SERVICE_CONFIG: /config/api_v1.hcl
      CENTRAL_CONFIG: "/central_config/api_defaults.hcl"
    volumes:
    - "./fake-service/service_config:/config"
    - "./fake-service/central_config:/central_config"
    command: ["consul", "connect", "envoy", "-sidecar-for", "api-v1"]
    network_mode: "service:api"
EOF

# Start fake-service container using docker-compose
cd /opt/consul/fake-service
docker compose up -d

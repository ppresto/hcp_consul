# OpenTracing with Jaeger and fake-service

## Deploy fake-service
use kubectl to manually deploy consul servicedefaults, intentions, and fake-services.
```
cd /Users/patrickpresto/Projects/hcp/hcp-consul/aws_eks_apps/templates/fs-tp
kubectl apply -f .
kubectl apply -f ./init-consul-config
kubectl get pods -A -l service=fake-service
```
### Get URL
```
#list ports (default 8080)
kubectl get svc consul-ingress-gateway -o json | jq -r '.spec.ports[].port'

# output URL
echo "http://$(kubectl get svc consul-ingress-gateway -o json | jq -r '.status.loadBalancer.ingress[].hostname'):8080"
```

## Run Jaeger
Its recommended to use the Jaeger operator in K8s, but you can also generate the needed yaml from the jaeger-operator's `simplest` example for a quick dev env.  This example will generate the yaml for the latest all-in-one version so backup existing configs.
```
curl https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/examples/simplest.yaml | docker run -i --rm jaegertracing/jaeger-operator:master generate > jaeger-all-in-one.yaml
```
Once deployed you will have a few services and the simplest pod runnning.  This is Jaeger.

To view the UI use kubernetes port forwarding.
```
export POD_NAME=$(kubectl get pods -l app.kubernetes.io/instance=simplest -o name)
kubectl port-forward ${POD_NAME} 16686:16686
```

### Review Jaeger Trace examples

## Setup EC2 Ubuntu Instance
Install Envoy
```
curl https://func-e.io/install.sh | sudo bash -s -- -b /usr/local/bin
func-e versions -all
func-e use 1.20.2
sudo cp /home/ubuntu/.func-e/versions/1.20.2/bin/envoy /usr/local/bin
envoy --version
```

Install Docker
```
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Test Installation
sudo docker run hello-world
docker compose version

# install loki log driver
sudo docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
```
To install specific versions of docker...
```
#search versions (2nd column)
apt-cache madison docker-ce

#install specific version
sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io docker-compose-plugin
```
## Troubleshooting

### Helm
Manually install consul using Helm.  The test.yaml was take from TFCB Output.
```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install consul hashicorp/consul --create-namespace --namespace consul --version 0.33.0 --set global.image="hashicorp/consul-enterprise:1.11.0-ent" --values ./helm/test.yaml
helm status consul
```

### Kubernetes

For proxy global default changes to take affect restart envoy sidecars with rolling deployment.
```
for i in  $(kubectl get deployments -l service=fake-service -o name); do kubectl rollout restart $i; done
```

#### Terminate stuck namespace

Start proxy on localhost:8001
```
kubectl proxy
```

Use k8s API to delete namespace
```
cat <<EOF | curl -X PUT \
  localhost:8001/api/v1/namespaces/currency-ns/finalize \
  -H "Content-Type: application/json" \
  --data-binary @-
{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "currency-ns"
  },
  "spec": {
    "finalizers": null
  }
}
EOF
```

Find finalizers in "spec"
```
kubectl get namespace api -o json > temp.json
```

```
"spec": {
        "finalizers": []
    }
```
#### Terminate stuck servicedefault
```
kubectl patch servicedefaults.consul.hashicorp.com currency --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch servicedefaults.consul.hashicorp.com api -n api-ns --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch ingressgateway.consul.hashicorp.com ingress-gateway --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch serviceintentions.consul.hashicorp.com cache --type merge --patch '{"metadata":{"finalizers":[]}}'
kubectl patch serviceintentions.consul.hashicorp.com currency --type merge --patch '{"metadata":{"finalizers":[]}}'
kubectl patch serviceintentions.consul.hashicorp.com web --type merge --patch '{"metadata":{"finalizers":[]}}'
kubectl patch serviceintentions.consul.hashicorp.com payments --type merge --patch '{"metadata":{"finalizers":[]}}'
```
# OpenTracing with Jaeger and fake-service

## Access fake-service
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

### Helm
Manually install consul using Helm
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
kubectl patch servicedefaults.consul.hashicorp.com web --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch servicedefaults.consul.hashicorp.com api --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch ingressgateway.consul.hashicorp.com ingress-gateway --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch serviceintentions.consul.hashicorp.com cache --type merge --patch '{"metadata":{"finalizers":[]}}'
kubectl patch serviceintentions.consul.hashicorp.com currency --type merge --patch '{"metadata":{"finalizers":[]}}'
kubectl patch serviceintentions.consul.hashicorp.com web --type merge --patch '{"metadata":{"finalizers":[]}}'
kubectl patch serviceintentions.consul.hashicorp.com payments --type merge --patch '{"metadata":{"finalizers":[]}}'
```
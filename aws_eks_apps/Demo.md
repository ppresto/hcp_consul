# Demo

## Review Current Environment
* Walk through [TFCB Workspaces](https://app.terraform.io/app/presto-projects/workspaces)
* HCP, AWS VPC/TG, EKS cluster with basic web and api services
* [Show Consul Dashboard](https://hcpc-cluster-presto.consul.328306de-41b8-43a7-9c38-ca8d89d06b07.aws.hashicorp.cloud/ui/~api-ns/hcpc-cluster-presto/services/api/intentions) (No services)
## Fake-Service App
Show current K8s cluster pods in real time for transparency
```
watch kubectl get pods -A
```

Deploy fs to show normal (no consul, no mesh) service running in K8s.  This can be used as a starting point to show existing services day 1.
```
cd aws_eks_apps/templates/fs-ns-tp
kubectl apply -f .
kubectl get pods -A -l service=fake-service
```
## Test Service locally
```
kubectl port-forward svc/web 9090:9090
```
http://localhost:9090/ui

## Deploy Consul

TFCB - Run presto-projects: aws_eks_apps to run Consul helm chart and deploy agent to EKS.  

## Redeploy Services
Rolling deploy, scale down, or delete services.
```
#kubectl rollout restart deployment web
#kubectl scale deployment web --replicas=0
#kubectl delete $(kubectl get pods -l service=fake-service)


kubectl apply -f ./init-consul-config/
kubectl delete -f .
kubectl apply -f .
kubectl apply -f ./init-consul-config/
```

## Review Consul Dashboard
View K8s namespace/service mapping
```
kubectl get pods -A -l service=fake-service
```

* View Consul Dashboard Namespace mapping 
* Admin Partitions vs Namespaces
* Namespaces -> default
* Services -> Web  - Topology, Intentions

## Test Ingress GW
TFCB - Open Ingress GW URL
```
echo "http://$(kubectl get svc consul-ingress-gateway -n consul -o json | jq -r '.status.loadBalancer.ingress[].hostname'):8080/ui"
```
## Deploy api-v2
```
cd release-v2
kubectl apply -f ./api-v2.yaml
kubectl apply -f ./traffic-mgmt.yaml
```
Review api service router/splitter using traffic-mgmt.yaml and Consul UI together.

## Test api-v2 Service Routing by Header
Find Service Ingress Gateway Address from TFCB. 
* access service v1
* update baggage header using modHeaders `baggage: version=2`
* refresh to see v2 which has additional upstreams.
* Unset modheaders
* refresh to see v1

## Show Service Splitting
Update traffic-mgmt.yaml to split 50/50
```
kubectl apply -f .
```
Refresh multiple times.

## Clean up
```
cd $HOME/Projects/hcp/hcp-consul/aws_eks_apps/templates/fs-ns-tp
kubectl delete -f init-consul-config/
kubectl delete -f .
kubectl get serviceDefaults
kubectl get serviceIntentions
kubectl get serviceRouters
kubectl get serviceSplitters
kubectl get serviceResolvers
kubectl get ns

source scripts/setConsulEnv.sh <CONSUL_TOKEN>
consul namespace delete api-ns
consul namespace delete payments-ns
consul namespace delete currency-ns
```
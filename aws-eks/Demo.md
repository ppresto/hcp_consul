# Demo

## Review Current Environment
* Walk through TFCB Workspaces (HCP, AWS VPC/TG, EKS cluster with basic web and api services).  
* Show Consul Dashboard (No services)
## Fake-Service App
Deploy fs to show normal (no consul, no mesh) service running in K8s.  This can be used as a starting point to show existing services day 1.
```
cd aws_eks_apps/templates/fs-ns-tp
kubectl apply -f .
kubectl get pods -A -l service=fake-service
```
## Get Service URL
```
kubectl port-forward svc/web 9090:9090
```
http://localhost:9090/ui
## Deploy Consul
TFCB - Run presto-projects: aws_eks_apps to run Consul helm chart and deploy agent to EKS.

## Redeploy Services
Rolling deploy, scale down, or delete services.
```
kubectl rollout restart deployment web
kubectl scale deployment web --replicas=0
kubectl delete $(kubectl get pods -l app=web)
```

## Review Consul Dashboard

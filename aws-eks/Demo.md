# Demo

## Review Current Environment
Walk through TFCB Workspaces (HCP, AWS VPC/TG, EKS cluster with basic web and api services).  
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


## Test Service locally (Optional)
Verify fs output on CLI
```
kubectl exec -it $(kubectl get pod -l app=web -o name) -c web -- curl http://localhost:9090

kubectl exec -it $(kubectl get pod -l app=api -o name) -c api -- curl http://localhost:9091
```

## Deploy Consul

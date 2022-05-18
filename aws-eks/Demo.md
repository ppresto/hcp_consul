# Demo

## Review Environment
Walk through TFCB Workspaces (HCP, VPC/TG, EKS, aws_eks_apps).  
## Fake-Service App
Deploy fs to show normal (no consul, no mesh) service running in K8s.  This can be used as a starting point to show existing services day 1.

## Get Service URL
```
kubectl port-forward svc/web 9090:9090
```
http://localhost:9090/ui


## Local - Test Service locally
Verify fs output on CLI
```
kubectl exec -it $(kubectl get pod -l app=web -o name) -c web -- curl http://localhost:9090

kubectl exec -it $(kubectl get pod -l app=api -o name) -c api -- curl http://localhost:9091
```
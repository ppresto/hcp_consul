# Fake-Service App

Deploy fs to show normal (no consul, no mesh) service running in K8s.  This can be used as a starting point to show existing services day 1.

## Get Service URL
```
echo "http://$(kubectl get svc web-ingress -o json | jq -r '.status.loadBalancer.ingress[].hostname'):9090"
```

## Local - Test Service locally
Verify fs output on CLI
```
kubectl exec -it $(kubectl get pod -l app=web -o name) -c web -- curl http://localhost:9090

kubectl exec -it $(kubectl get pod -l app=api -o name) -c api -- curl http://localhost:9091
```
# Notes

```
cd ./api-release-v2
kubectl apply -f api-traffic-mgmt.yaml
kubectl apply -f api-v2.yaml
```

Test API version from CLI in While Loop
```
HOST=$(kubectl get svc -o json | jq -r '.items[].status.loadBalancer.ingress | select( . != null) | .[].hostname')

while true; do curl -s http://${HOST}:8080/ | jq -r '.upstream_calls."http://api:9091".name'; sleep 1; done
```


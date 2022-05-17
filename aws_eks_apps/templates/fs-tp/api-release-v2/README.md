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

## Chrome
Download Chrome Extension: ModHeaders and go to the /ui path for a better visual.

`URL: http://${HOST}:8080/ui/`

Update ModHeaders -> Profile 1 -> request header with the following `key=value`
```
baggage: userid=me;version=2;type=beta;trace=data
```
Enable or disable the header to control which version of api svc you route to.
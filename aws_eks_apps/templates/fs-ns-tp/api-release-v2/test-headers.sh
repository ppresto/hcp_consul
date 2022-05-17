#!/bin/bash

HOST=$(kubectl get svc -o json | jq -r '.items[].status.loadBalancer.ingress | select( . != null) | .[].hostname')

curl \
    --header "baggage:version=2;app=api;trace=data" \
    --request GET \
   http://${HOST}:8080

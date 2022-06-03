#!/bin/bash

HOST=$(kubectl get svc -o json | jq -r '.items[].status.loadBalancer.ingress | select( . != null) | .[].hostname')

curl \
    --header "baggage:userid=presto;version=2;app=beta;trace=somedata" \
    --request GET \
   http://${HOST}:8080

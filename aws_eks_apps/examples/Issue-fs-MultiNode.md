# Fake Service Errors

web receives 504 Error from upstream service - api.  This appears to happen when services are on different Nodes of the EKS cluster.  Why?

```
➜  x fs-tp (main)
     $  kubectl exec -it $(kubectl get pod -l app=web -o name) -c web -- curl http://localhost:9090
{
  "name": "web",
  "uri": "/",
  "type": "HTTP",
  "ip_addresses": [
    "10.20.3.215"
  ],
  "start_time": "2022-05-14T07:08:54.855195",
  "end_time": "2022-05-14T07:08:54.863842",
  "duration": "8.646876ms",
  "body": "Hello World",
  "upstream_calls": {
    "http://api:9091": {
      "uri": "http://api:9091",
      "headers": {
        "Content-Length": "19",
        "Content-Type": "text/plain",
        "Date": "Sat, 14 May 2022 07:08:54 GMT",
        "Server": "envoy"
      },
      "code": 503,
      "error": "Error processing upstream request: http://api:9091/, expected code 200, got 503"
    }
  },
  "code": 500
}
```

Replicate by configuring init consul requirements: service defaults, and intentions.  Then start the downstream service followed by the upstream service.
```
kubectl apply -f ./templates/fs-tp/init-consul-config/
kubectl apply -f ./templates/fs-tp/web.yaml
kubectl apply -f ./templates/fs-tp/api.yaml
```

Test Response - Error code: 504
```
kubectl exec -it $(kubectl get pod -l app=web -o name) -c web -- curl http://localhost:9090
```

Resolve Error by restarting downstream pod (web).
```
kubectl delete $(kubectl get pod -l app=web -o name)
```
Test Response again.  You should see - 200

ReIntroduce the Error by deleting/restarting the upstream pod (api)
```
kubectl delete $(kubectl get pod -l app=api -o name)
```
Can't get healthy this time.  
What is "10.20.3.189:8502" ?  Can't find this pod IP anywhere...
Output...

```
➜  x fs-tp (main)
     $  kubectl get svc web
NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
web    ClusterIP   172.20.190.27   <none>        9090/TCP   96m
➜  x fs-tp (main)
     $  kubectl get pods -l app=web -o wide
NAME                  READY   STATUS    RESTARTS   AGE     IP            NODE                                        NOMINATED NODE   READINESS GATES
web-97b47b896-wjggk   2/2     Running   0          5m13s   10.20.3.117   ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
➜  x fs-tp (main)
     $  kubectl exec -it $(kubectl get pod -l app=web -o name) -c web -- ping api.default
PING api.default (172.20.106.107): 56 data bytes
^C
--- api.default ping statistics ---
4 packets transmitted, 0 packets received, 100% packet loss
command terminated with exit code 1
➜  x fs-tp (main)
     $  kubectl get svc api
NAME   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
api    ClusterIP   172.20.106.107   <none>        9091/TCP   100m
➜  x fs-tp (main)
     $  kubectl get pods -l app=api -o wide
NAME                                 READY   STATUS    RESTARTS   AGE   IP           NODE                                       NOMINATED NODE   READINESS GATES
api-deployment-v1-57c8656457-2vl76   2/2     Running   0          92m   10.20.1.62   ip-10-20-1-78.us-west-2.compute.internal   <none>           <none>

➜  x fs-tp (main)
     $  kubectl exec -it $(kubectl get pod -l app=web -o name) -c web -- netstat -an
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 127.0.0.1:19000         0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:15001         0.0.0.0:*               LISTEN
tcp        0      0 10.20.3.117:20000       0.0.0.0:*               LISTEN
tcp        0      0 10.20.3.117:46232       172.20.91.125:9411      ESTABLISHED
tcp        0      1 10.20.3.117:46234       172.20.91.125:9411      SYN_SENT
tcp     1126      0 127.0.0.1:15001         10.20.3.117:46232       ESTABLISHED
tcp        0      0 10.20.3.117:37496       10.20.3.189:8502        ESTABLISHED
tcp        0      0 :::9090                 :::*                    LISTEN
Active UNIX domain sockets (servers and established)
Proto RefCnt Flags       Type       State         I-Node Path
unix  2      [ ]         DGRAM                    6150507 @envoy_domain_socket_parent_0@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
unix  2      [ ]         DGRAM                    6150506 @envoy_domain_socket_child_0@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
➜  x fs-tp (main)
     $  kubectl get pods -o wide
NAME                                                         READY   STATUS    RESTARTS   AGE     IP            NODE                                        NOMINATED NODE   READINESS GATES
api-deployment-v1-57c8656457-2vl76                           2/2     Running   0          97m     10.20.1.62    ip-10-20-1-78.us-west-2.compute.internal    <none>           <none>
consul-9sh8t                                                 1/1     Running   0          24h     10.20.3.164   ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
consul-connect-injector-webhook-deployment-85db569bb-bwvlx   1/1     Running   0          24h     10.20.1.134   ip-10-20-1-78.us-west-2.compute.internal    <none>           <none>
consul-connect-injector-webhook-deployment-85db569bb-nscvm   1/1     Running   0          24h     10.20.3.115   ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
consul-controller-55d966b4bd-thbl8                           1/1     Running   0          24h     10.20.3.82    ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
consul-gqtjp                                                 1/1     Running   0          24h     10.20.1.136   ip-10-20-1-78.us-west-2.compute.internal    <none>           <none>
consul-ingress-gateway-74c97db57f-x4msh                      2/2     Running   0          24h     10.20.3.62    ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
consul-webhook-cert-manager-65b8bb9785-kqhff                 1/1     Running   0          24h     10.20.1.79    ip-10-20-1-78.us-west-2.compute.internal    <none>           <none>
simplest-59ccc99bcc-l7xl9                                    1/1     Running   0          99m     10.20.1.12    ip-10-20-1-78.us-west-2.compute.internal    <none>           <none>
web-97b47b896-wjggk                                          2/2     Running   0          6m21s   10.20.3.117   ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
➜  x fs-tp (main)
     $  kubectl get svc
NAME                          TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)                                  AGE
api                           ClusterIP      172.20.106.107   <none>                                                                    9091/TCP                                 105m
consul-connect-injector-svc   ClusterIP      172.20.16.9      <none>                                                                    443/TCP                                  24h
consul-controller-webhook     ClusterIP      172.20.193.206   <none>                                                                    443/TCP                                  24h
consul-ingress-gateway        LoadBalancer   172.20.167.93    a24dd62238ae14ad38f7bd96071f855a-2112322454.us-west-2.elb.amazonaws.com   8080:30282/TCP,8443:30511/TCP            24h
kubernetes                    ClusterIP      172.20.0.1       <none>                                                                    443/TCP                                  41h
simplest-agent                ClusterIP      None             <none>                                                                    5775/UDP,5778/TCP,6831/UDP,6832/UDP      99m
simplest-collector            ClusterIP      172.20.91.125    <none>                                                                    9411/TCP,14250/TCP,14267/TCP,14268/TCP   99m
simplest-collector-headless   ClusterIP      None             <none>                                                                    9411/TCP,14250/TCP,14267/TCP,14268/TCP   99m
simplest-query                ClusterIP      172.20.29.63     <none>                                                                    16686/TCP,16685/TCP                      99m
web                           ClusterIP      172.20.190.27    <none>                                                                    9090/TCP                                 98m
```

Lets try to remove the deployment completely and start over...
```
kubectl delete -f web.yaml
```
This froze.  The only way to complete the command is remove servicedefault finalizer.
```
kubectl patch servicedefaults.consul.hashicorp.com web --type merge --patch '{"metadata":{"finalizers":[]}}'
```
Note:  servicedefaults were being defined with the deployment.  I moved these to only exist in the init-consul-config/ so they are seperate.

Lets redeploy and test ...
```
kubectl apply -f templates/fs-tp/init-consul-config/servicedefaults.yaml
kubectl apply -f tempmlates/fs-tp/main.yaml
kubectl exec -it $(kubectl get pod -l app=web -o name) -c web -- curl http://localhost:9090
```

Still broken???


looking at envoy-sidecar.
```
➜  x fs-tp (main)
     $  kubectl exec -it $(kubectl get pod -l app=web -o name) -c envoy-sidecar -- wget -qO- http://localhost:19000/clusters
original-destination::observability_name::original-destination
original-destination::default_priority::max_connections::1024
original-destination::default_priority::max_pending_requests::1024
original-destination::default_priority::max_requests::1024
original-destination::default_priority::max_retries::3
original-destination::high_priority::max_connections::1024
original-destination::high_priority::max_pending_requests::1024
original-destination::high_priority::max_requests::1024
original-destination::high_priority::max_retries::3
original-destination::added_via_api::true
original-destination::172.20.91.125:9411::cx_active::1
original-destination::172.20.91.125:9411::cx_connect_fail::4920
original-destination::172.20.91.125:9411::cx_total::4921
original-destination::172.20.91.125:9411::rq_active::0
original-destination::172.20.91.125:9411::rq_error::0
original-destination::172.20.91.125:9411::rq_success::0
original-destination::172.20.91.125:9411::rq_timeout::0
original-destination::172.20.91.125:9411::rq_total::0
original-destination::172.20.91.125:9411::hostname::original-destination172.20.91.125:9411
original-destination::172.20.91.125:9411::health_flags::healthy
original-destination::172.20.91.125:9411::weight::1
original-destination::172.20.91.125:9411::region::
original-destination::172.20.91.125:9411::zone::
original-destination::172.20.91.125:9411::sub_zone::
original-destination::172.20.91.125:9411::canary::false
original-destination::172.20.91.125:9411::priority::0
original-destination::172.20.91.125:9411::success_rate::-1.0
original-destination::172.20.91.125:9411::local_origin_success_rate::-1.0
local_app::observability_name::local_app
local_app::default_priority::max_connections::1024
local_app::default_priority::max_pending_requests::1024
local_app::default_priority::max_requests::1024
local_app::default_priority::max_retries::3
local_app::high_priority::max_connections::1024
local_app::high_priority::max_pending_requests::1024
local_app::high_priority::max_requests::1024
local_app::high_priority::max_retries::3
local_app::added_via_api::true
local_app::127.0.0.1:9090::cx_active::0
local_app::127.0.0.1:9090::cx_connect_fail::0
local_app::127.0.0.1:9090::cx_total::17
local_app::127.0.0.1:9090::rq_active::0
local_app::127.0.0.1:9090::rq_error::4
local_app::127.0.0.1:9090::rq_success::0
local_app::127.0.0.1:9090::rq_timeout::0
local_app::127.0.0.1:9090::rq_total::17
local_app::127.0.0.1:9090::hostname::
local_app::127.0.0.1:9090::health_flags::healthy
local_app::127.0.0.1:9090::weight::1
local_app::127.0.0.1:9090::region::
local_app::127.0.0.1:9090::zone::
local_app::127.0.0.1:9090::sub_zone::
local_app::127.0.0.1:9090::canary::false
local_app::127.0.0.1:9090::priority::0
local_app::127.0.0.1:9090::success_rate::-1.0
local_app::127.0.0.1:9090::local_origin_success_rate::-1.0
local_agent::observability_name::local_agent
local_agent::default_priority::max_connections::1024
local_agent::default_priority::max_pending_requests::1024
local_agent::default_priority::max_requests::1024
local_agent::default_priority::max_retries::3
local_agent::high_priority::max_connections::1024
local_agent::high_priority::max_pending_requests::1024
local_agent::high_priority::max_requests::1024
local_agent::high_priority::max_retries::3
local_agent::added_via_api::false
local_agent::10.20.3.189:8502::cx_active::1
local_agent::10.20.3.189:8502::cx_connect_fail::0
local_agent::10.20.3.189:8502::cx_total::1
local_agent::10.20.3.189:8502::rq_active::1
local_agent::10.20.3.189:8502::rq_error::0
local_agent::10.20.3.189:8502::rq_success::0
local_agent::10.20.3.189:8502::rq_timeout::0
local_agent::10.20.3.189:8502::rq_total::1
local_agent::10.20.3.189:8502::hostname::
local_agent::10.20.3.189:8502::health_flags::healthy
local_agent::10.20.3.189:8502::weight::1
local_agent::10.20.3.189:8502::region::
local_agent::10.20.3.189:8502::zone::
local_agent::10.20.3.189:8502::sub_zone::
local_agent::10.20.3.189:8502::canary::false
local_agent::10.20.3.189:8502::priority::0
local_agent::10.20.3.189:8502::success_rate::-1.0
local_agent::10.20.3.189:8502::local_origin_success_rate::-1.0
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::observability_name::v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::outlier::success_rate_average::-1
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::outlier::success_rate_ejection_threshold::-1
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::outlier::local_origin_success_rate_average::-1
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::outlier::local_origin_success_rate_ejection_threshold::-1
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::default_priority::max_connections::1024
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::default_priority::max_pending_requests::1024
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::default_priority::max_requests::1024
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::default_priority::max_retries::3
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::high_priority::max_connections::1024
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::high_priority::max_pending_requests::1024
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::high_priority::max_requests::1024
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::high_priority::max_retries::3
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::added_via_api::true
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::10.20.1.62:20000::cx_active::0
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::10.20.1.62:20000::cx_connect_fail::35
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::10.20.1.62:20000::cx_total::35
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::10.20.1.62:20000::rq_active::0
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::10.20.1.62:20000::rq_error::19
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::10.20.1.62:20000::rq_success::0
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::10.20.1.62:20000::rq_timeout::0
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::10.20.1.62:20000::rq_total::0
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::10.20.1.62:20000::hostname::
v1.api.default.hcpc-cluster-presto.internal.581aa194-4ae7-b07c-bca6-9475ad2164ef.consul::10.20.1.62:20000::health_flags::healthy
```
What is the envoy local_agent?  It appears to be mapped to the IP I can't find.
local_agent::10.20.3.189:8502::cx_active::1

web envoy-sidecar netstat/ifconfig:
ifconfig shows envoy-sidecar running on the same pod IP as the consul client pod.
```
➜  x fs-tp (main)
     $  kubectl exec -it $(kubectl get pod -l app=web -o name) -c envoy-sidecar -- sh
/ $ netstat -an
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 127.0.0.1:19000         0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:15001         0.0.0.0:*               LISTEN
tcp        0      0 10.20.3.164:20000       0.0.0.0:*               LISTEN
tcp        0      0 10.20.3.164:34284       10.20.3.189:8502        ESTABLISHED
tcp    18612      0 127.0.0.1:15001         10.20.3.164:36028       ESTABLISHED
tcp        0      1 10.20.3.164:36030       172.20.91.125:9411      SYN_SENT
tcp        0      0 10.20.3.164:36028       172.20.91.125:9411      ESTABLISHED
tcp        0      0 :::9090                 :::*                    LISTEN
Active UNIX domain sockets (servers and established)
Proto RefCnt Flags       Type       State         I-Node Path
unix  2      [ ]         DGRAM                    6201148 @envoy_domain_socket_parent_0@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
unix  2      [ ]         DGRAM                    6201147 @envoy_domain_socket_child_0@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/ $ ifconfig -a
eth0      Link encap:Ethernet  HWaddr F2:8D:21:A8:0C:5D
          inet addr:10.20.3.164  Bcast:0.0.0.0  Mask:255.255.255.255
          UP BROADCAST RUNNING MULTICAST  MTU:9001  Metric:1
          RX packets:20756 errors:0 dropped:0 overruns:0 frame:0
          TX packets:32203 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:2643863 (2.5 MiB)  TX bytes:2783004 (2.6 MiB)
```


api netstat output and envoy-sidecar /clusters output
```
➜  x fs-tp (main)
     $  kubectl exec -it $(kubectl get pod -l app=api -o name) -c api -- netstat -an
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 127.0.0.1:19000         0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:15001         0.0.0.0:*               LISTEN
tcp        0      0 10.20.1.62:20000        0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:9091          0.0.0.0:*               LISTEN
tcp        0      0 10.20.1.62:35376        10.20.1.78:8502         ESTABLISHED
Active UNIX domain sockets (servers and established)
Proto RefCnt Flags       Type       State         I-Node Path

➜  x fs-tp (main)
     $  kubectl exec -it $(kubectl get pod -l app=api -o name) -c envoy-sidecar -- wget -qO- http://localhost:19000/clusters
local_agent::observability_name::local_agent
local_agent::default_priority::max_connections::1024
local_agent::default_priority::max_pending_requests::1024
local_agent::default_priority::max_requests::1024
local_agent::default_priority::max_retries::3
local_agent::high_priority::max_connections::1024
local_agent::high_priority::max_pending_requests::1024
local_agent::high_priority::max_requests::1024
local_agent::high_priority::max_retries::3
local_agent::added_via_api::false
local_agent::10.20.1.78:8502::cx_active::1
local_agent::10.20.1.78:8502::cx_connect_fail::5
local_agent::10.20.1.78:8502::cx_total::7
local_agent::10.20.1.78:8502::rq_active::1
local_agent::10.20.1.78:8502::rq_error::6
local_agent::10.20.1.78:8502::rq_success::0
local_agent::10.20.1.78:8502::rq_timeout::0
local_agent::10.20.1.78:8502::rq_total::2
local_agent::10.20.1.78:8502::hostname::
local_agent::10.20.1.78:8502::health_flags::healthy
local_agent::10.20.1.78:8502::weight::1
local_agent::10.20.1.78:8502::region::
local_agent::10.20.1.78:8502::zone::
local_agent::10.20.1.78:8502::sub_zone::
local_agent::10.20.1.78:8502::canary::false
local_agent::10.20.1.78:8502::priority::0
local_agent::10.20.1.78:8502::success_rate::-1.0
local_agent::10.20.1.78:8502::local_origin_success_rate::-1.0
local_app::observability_name::local_app
local_app::default_priority::max_connections::1024
local_app::default_priority::max_pending_requests::1024
local_app::default_priority::max_requests::1024
local_app::default_priority::max_retries::3
local_app::high_priority::max_connections::1024
local_app::high_priority::max_pending_requests::1024
local_app::high_priority::max_requests::1024
local_app::high_priority::max_retries::3
local_app::added_via_api::true
local_app::127.0.0.1:9091::cx_active::0
local_app::127.0.0.1:9091::cx_connect_fail::0
local_app::127.0.0.1:9091::cx_total::0
local_app::127.0.0.1:9091::rq_active::0
local_app::127.0.0.1:9091::rq_error::0
local_app::127.0.0.1:9091::rq_success::0
local_app::127.0.0.1:9091::rq_timeout::0
local_app::127.0.0.1:9091::rq_total::0
local_app::127.0.0.1:9091::hostname::
local_app::127.0.0.1:9091::health_flags::healthy
local_app::127.0.0.1:9091::weight::1
local_app::127.0.0.1:9091::region::
local_app::127.0.0.1:9091::zone::
local_app::127.0.0.1:9091::sub_zone::
local_app::127.0.0.1:9091::canary::false
local_app::127.0.0.1:9091::priority::0
local_app::127.0.0.1:9091::success_rate::-1.0
local_app::127.0.0.1:9091::local_origin_success_rate::-1.0
original-destination::observability_name::original-destination
original-destination::default_priority::max_connections::1024
original-destination::default_priority::max_pending_requests::1024
original-destination::default_priority::max_requests::1024
original-destination::default_priority::max_retries::3
original-destination::high_priority::max_connections::1024
original-destination::high_priority::max_pending_requests::1024
original-destination::high_priority::max_requests::1024
original-destination::high_priority::max_retries::3
original-destination::added_via_api::true

```

envoy-sidecar /config_dump shows the local_agent ip:port
```
"static_resources": {
     "clusters": [
      {
       "name": "local_agent",
       "type": "STATIC",
       "connect_timeout": "1s",
       "http2_protocol_options": {},
       "transport_socket": {
        "name": "tls",
        "typed_config": {
         "@type": "type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext",
         "common_tls_context": {
          "validation_context": {
           "trusted_ca": {
            "inline_string": "-----BEGIN CERTIFICATE-----\nMIICDjCCAbWgAwIBAgIBCzAKBggqhkjOPQQDAjAxMS8wLQYDVQQDEyZwcmktZG4z\naTMwdHIuY29uc3VsLmNhLjU4MWFhMTk0LmNvbnN1bDAeFw0yMjA0MjcwMDMwMzda\nFw0zMjA0MjQwMDMwMzdaMDExLzAtBgNVBAMTJnByaS1kbjNpMzB0ci5jb25zdWwu\nY2EuNTgxYWExOTQuY29uc3VsMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEMTd0\nRAysCRDjKT7OyDmNG9n4rGL4Z5ou9gf7L0vf1718aOYoacNRrV55+u2SDhye80D7\npwSO/3JEN1lUGBVdGaOBvTCBujAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUw\nAwEB/zApBgNVHQ4EIgQg/HcgDGqmhMQqtYix7ijAP5ffawI50H4Ho7LC7ZpMJkww\nKwYDVR0jBCQwIoAg/HcgDGqmhMQqtYix7ijAP5ffawI50H4Ho7LC7ZpMJkwwPwYD\nVR0RBDgwNoY0c3BpZmZlOi8vNTgxYWExOTQtNGFlNy1iMDdjLWJjYTYtOTQ3NWFk\nMjE2NGVmLmNvbnN1bDAKBggqhkjOPQQDAgNHADBEAiBTwB1AY/NiLpYofWZ97voR\nH9vq8gLmz/EGdkTqsfTq+AIgc2Qnf9eBR3WoK+NViafaQB2H6BFqEZhSMN0ZkhQo\nMng=\n-----END CERTIFICATE-----\n\n"
           }
          }
         }
        }
       },
       "load_assignment": {
        "cluster_name": "local_agent",
        "endpoints": [
         {
          "lb_endpoints": [
           {
            "endpoint": {
             "address": {
              "socket_address": {
               "address": "10.20.1.78",
               "port_value": 8502
              }
             }
            }
           }
          ]
         }
        ]
       }
      }
     ]
    },
```

The API envoy sidecar has the same ip as the api pod.  This is different then web!
```
➜  x fs-tp (main)
     $  kubectl exec -it $(kubectl get pod -l app=api -o name) -c envoy-sidecar -- sh
/ $ ifconfig
eth0      Link encap:Ethernet  HWaddr 2E:C4:0F:0F:E7:B1
          inet addr:10.20.1.62  Bcast:0.0.0.0  Mask:255.255.255.255
          UP BROADCAST RUNNING MULTICAST  MTU:9001  Metric:1
          RX packets:12941 errors:0 dropped:0 overruns:0 frame:0
          TX packets:7093 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:894867 (873.8 KiB)  TX bytes:590461 (576.6 KiB)

/ $ netstat -an
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 127.0.0.1:19000         0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:15001         0.0.0.0:*               LISTEN
tcp        0      0 10.20.1.62:20000        0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:9091          0.0.0.0:*               LISTEN
tcp        0      0 10.20.1.62:35376        10.20.1.78:8502         ESTABLISHED
Active UNIX domain sockets (servers and established)
Proto RefCnt Flags       Type       State         I-Node Path
```

Review api pod and envoy-sidecar IP:20000
```
➜  x fs-tp (main)
     $  kubectl exec -it $(kubectl get pod -l app=api -o name) -c envoy-sidecar -- netstat -an | grep 20000
tcp        0      0 10.20.1.62:20000        0.0.0.0:*               LISTEN
➜  x fs-tp (main)
     $  kubectl get $(kubectl get pod -l app=api -o name) -o wide
NAME                                 READY   STATUS    RESTARTS   AGE   IP           NODE                                       NOMINATED NODE   READINESS GATES
api-deployment-v1-57c8656457-2vl76   2/2     Running   0          8h    10.20.1.62   ip-10-20-1-78.us-west-2.compute.internal   <none>           <none>
```
Review web pod and envoy-sidecar IP:20000
```
➜  x fs-tp (main)
     $  kubectl get $(kubectl get pod -l app=web -o name) -o wide
NAME                  READY   STATUS    RESTARTS   AGE     IP            NODE                                        NOMINATED NODE   READINESS GATES
web-97b47b896-rqz6h   2/2     Running   0          6h35m   10.20.3.164   ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
➜  x fs-tp (main)
     $  kubectl exec -it $(kubectl get pod -l app=web -o name) -c envoy-sidecar -- netstat -an | grep 20000
tcp        0      0 10.20.3.164:20000       0.0.0.0:*               LISTEN
```

Do fs pods on different nodes cause the problem?  Downgrading to 1 node cluster now to test.
```
➜  ✓ fs-tp (main)
     $  kubectl get pods -o wide
NAME                                                         READY   STATUS    RESTARTS   AGE     IP            NODE                                        NOMINATED NODE   READINESS GATES
api-deployment-v1-57c8656457-2vl76                           2/2     Running   0          8h      10.20.1.62    ip-10-20-1-78.us-west-2.compute.internal    <none>           <none>
consul-connect-injector-webhook-deployment-85db569bb-cqj6n   1/1     Running   0          6h54m   10.20.3.213   ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
consul-connect-injector-webhook-deployment-85db569bb-m5hbp   1/1     Running   0          6h54m   10.20.1.201   ip-10-20-1-78.us-west-2.compute.internal    <none>           <none>
consul-controller-55d966b4bd-thbl8                           1/1     Running   0          31h     10.20.3.82    ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
consul-ingress-gateway-74c97db57f-x4msh                      2/2     Running   0          31h     10.20.3.62    ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
consul-rnmzv                                                 1/1     Running   0          6h52m   10.20.1.134   ip-10-20-1-78.us-west-2.compute.internal    <none>           <none>
consul-v75tm                                                 1/1     Running   0          6h51m   10.20.3.117   ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
consul-webhook-cert-manager-65b8bb9785-kqhff                 1/1     Running   0          31h     10.20.1.79    ip-10-20-1-78.us-west-2.compute.internal    <none>           <none>
simplest-59ccc99bcc-l7xl9                                    1/1     Running   0          8h      10.20.1.12    ip-10-20-1-78.us-west-2.compute.internal    <none>           <none>
web-97b47b896-rqz6h                                          2/2     Running   0          6h51m   10.20.3.164   ip-10-20-3-189.us-west-2.compute.internal   <none>           <none>
```
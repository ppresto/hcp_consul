# Consul Errors

I reduced the EKS cluster from 2 medium nodes to 1 large.  Testing a theory with fake-service.  I ran the AWS EKS module with the above updates to update EKS.  The run completed.  My consul cluster is stuck in Initializing State.

```
➜  x fs-tp (main)
     $  kubectl get pods
NAME                                                         READY   STATUS     RESTARTS   AGE
consul-connect-injector-webhook-deployment-bbcdd5969-6lwxb   0/1     Init:1/2   0          6m16s
consul-connect-injector-webhook-deployment-bbcdd5969-vzw56   0/1     Init:1/2   0          6m15s
consul-controller-55d966b4bd-xr2p2                           0/1     Init:1/2   0          6m16s
consul-ingress-gateway-74c97db57f-bxvlk                      0/2     Init:1/3   0          6m15s
consul-kk8x9                                                 1/1     Running    0          6m56s
consul-webhook-cert-manager-65b8bb9785-twcgt                 1/1     Running    0          6m15s
```

kubectl describe pods doesn't show any obvious errors.  
client logs show it can't join old nodes, and they aren't able to connect.  this is expected since they are destroyed.
```
➜  x fs-tp (main)
     $  kubectl logs consul-kk8x9
==> Starting Consul agent...
           Version: '1.11.0+ent'
           Node ID: 'ef7e7a51-eebe-2992-721e-3e875d7f1a0e'
         Node name: 'ip-10-20-3-206.us-west-2.compute.internal'
        Datacenter: 'hcpc-cluster-presto' (Segment: '')
            Server: false (Bootstrap: false)
       Client Addr: [0.0.0.0] (HTTP: -1, HTTPS: 8501, gRPC: 8502, DNS: 8600)
      Cluster Addr: 10.20.3.84 (LAN: 8301, WAN: 8302)
           Encrypt: Gossip: true, TLS-Outgoing: true, TLS-Incoming: false, Auto-Encrypt-TLS: true

==> Log data will now stream in as it occurs:

2022-05-14T07:10:49.767Z [WARN]  agent: Node name "ip-10-20-3-206.us-west-2.compute.internal" will not be discoverable via DNS due to invalid characters. Valid characters include all alpha-numerics and dashes.
2022-05-14T07:10:49.871Z [WARN]  agent.auto_config: Node name "ip-10-20-3-206.us-west-2.compute.internal" will not be discoverable via DNS due to invalid characters. Valid characters include all alpha-numerics and dashes.
2022-05-14T07:10:49.969Z [INFO]  agent.auto_config: automatically upgraded to TLS
2022-05-14T07:10:49.986Z [INFO]  agent: successfully retrieved a license from the Consul Enterprise servers
2022-05-14T07:10:49.987Z [INFO]  agent: initialized license: id=81184069-9812-4a8a-80b8-cc968865a92e expiration="2022-06-17 18:57:04.035533865 +0000 UTC" features="Automated Backups, Automated Upgrades, Namespaces, SSO, Audit Logging, Admin Partitions"
2022-05-14T07:10:49.987Z [INFO]  agent: started routine: routine=license-manager
2022-05-14T07:10:49.987Z [INFO]  agent: started routine: routine=license-monitor
2022-05-14T07:10:49.987Z [INFO]  agent: started routine: routine=license-sync
2022-05-14T07:10:49.988Z [INFO]  agent.client.serf.lan: serf: EventMemberJoin: ip-10-20-3-206.us-west-2.compute.internal 10.20.3.84
2022-05-14T07:10:49.988Z [INFO]  agent.router: Initializing LAN area manager
2022-05-14T07:10:49.988Z [INFO]  agent.auto_config: auto-config started
2022-05-14T07:10:49.988Z [INFO]  agent: Started DNS server: address=0.0.0.0:8600 network=udp
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.063Z [WARN]  agent.cache: handling error in Cache.Notify: cache-type=connect-ca-root error="No known Consul servers" index=13
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.063Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.cache: handling error in Cache.Notify: cache-type=connect-ca-root error="No known Consul servers" index=13
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.cache: handling error in Cache.Notify: cache-type=connect-ca-root error="No known Consul servers" index=13
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.cache: handling error in Cache.Notify: cache-type=connect-ca-root error="No known Consul servers" index=13
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.cache: handling error in Cache.Notify: cache-type=connect-ca-root error="No known Consul servers" index=13
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.064Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.065Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.065Z [INFO]  agent: Started DNS server: address=0.0.0.0:8600 network=tcp
2022-05-14T07:10:50.065Z [WARN]  agent.cache: handling error in Cache.Notify: cache-type=connect-ca-root error="No known Consul servers" index=13
2022-05-14T07:10:50.066Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.066Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.066Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.066Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.065Z [WARN]  agent.cache: handling error in Cache.Notify: cache-type=connect-ca-root error="No known Consul servers" index=13
2022-05-14T07:10:50.066Z [WARN]  agent.cache: handling error in Cache.Notify: cache-type=connect-ca-root error="No known Consul servers" index=13
2022-05-14T07:10:50.066Z [INFO]  agent: Starting server: address=[::]:8501 network=tcp protocol=https
2022-05-14T07:10:50.066Z [WARN]  agent: DEPRECATED Backwards compatibility with pre-1.9 metrics enabled. These metrics will be removed in a future version of Consul. Set `telemetry { disable_compat_1.9 = true }` to disable them.
2022-05-14T07:10:50.066Z [INFO]  agent: Started gRPC server: address=[::]:8502 network=tcp
2022-05-14T07:10:50.066Z [INFO]  agent: started state syncer
2022-05-14T07:10:50.066Z [INFO]  agent: Consul agent running!
2022-05-14T07:10:50.067Z [INFO]  agent: Retry join is supported for the following discovery methods: cluster=LAN discovery_methods="aliyun aws azure digitalocean gce k8s linode mdns os packet scaleway softlayer tencentcloud triton vsphere"
2022-05-14T07:10:50.067Z [INFO]  agent: Joining cluster...: cluster=LAN
2022-05-14T07:10:50.067Z [INFO]  agent: (LAN) joining: lan_addresses=[hcpc-cluster-presto.private.consul.328306de-41b8-43a7-9c38-ca8d89d06b07.aws.hashicorp.cloud]
2022-05-14T07:10:50.067Z [WARN]  agent.router.manager: No servers available
2022-05-14T07:10:50.067Z [ERROR] agent.anti_entropy: failed to sync remote state: error="No known Consul servers"
2022-05-14T07:10:50.165Z [INFO]  agent.client.serf.lan: serf: EventMemberJoin: ip-10-20-11-75 10.20.11.75
2022-05-14T07:10:50.165Z [INFO]  agent.client.serf.lan: serf: EventMemberJoin: ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117
2022-05-14T07:10:50.165Z [INFO]  agent.client.serf.lan: serf: EventMemberJoin: ip-172-25-24-156 172.25.24.156
2022-05-14T07:10:50.165Z [INFO]  agent.client.serf.lan: serf: EventMemberJoin: ip-10-20-1-78.us-west-2.compute.internal 10.20.1.134
2022-05-14T07:10:50.166Z [INFO]  agent: (LAN) joined: number_of_nodes=1
2022-05-14T07:10:50.166Z [INFO]  agent: Join cluster completed. Synced with initial agents: cluster=LAN num_agents=1
2022-05-14T07:10:50.166Z [INFO]  agent.client: adding server: server="ip-172-25-24-156 (Addr: tcp/172.25.24.156:8300) (DC: hcpc-cluster-presto)"
2022-05-14T07:10:51.353Z [INFO]  agent: Synced node info
2022-05-14T07:12:26.990Z [INFO]  agent.client.memberlist.lan: memberlist: Suspect ip-10-20-3-189.us-west-2.compute.internal has failed, no acks received
2022-05-14T07:12:29.605Z [INFO]  agent.client.memberlist.lan: memberlist: Marking ip-10-20-3-189.us-west-2.compute.internal as failed, suspect timeout reached (2 peer confirmations)
2022-05-14T07:12:29.605Z [INFO]  agent.client.serf.lan: serf: EventMemberFailed: ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117
2022-05-14T07:12:29.991Z [INFO]  agent.client.memberlist.lan: memberlist: Suspect ip-10-20-3-189.us-west-2.compute.internal has failed, no acks received
2022-05-14T07:12:32.989Z [INFO]  agent.client.memberlist.lan: memberlist: Suspect ip-10-20-1-78.us-west-2.compute.internal has failed, no acks received
2022-05-14T07:12:32.990Z [INFO]  agent.client.memberlist.lan: memberlist: Marking ip-10-20-1-78.us-west-2.compute.internal as failed, suspect timeout reached (2 peer confirmations)
2022-05-14T07:12:32.990Z [INFO]  agent.client.serf.lan: serf: EventMemberFailed: ip-10-20-1-78.us-west-2.compute.internal 10.20.1.134
2022-05-14T07:12:50.067Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
2022-05-14T07:13:30.068Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
2022-05-14T07:14:10.069Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
2022-05-14T07:14:43.142Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-1-78.us-west-2.compute.internal 10.20.1.134:8301
2022-05-14T07:15:23.143Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
2022-05-14T07:15:56.198Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
2022-05-14T07:16:29.253Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-1-78.us-west-2.compute.internal 10.20.1.134:8301
2022-05-14T07:17:09.254Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
2022-05-14T07:17:42.309Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
2022-05-14T07:18:15.365Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
2022-05-14T07:18:48.421Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
2022-05-14T07:19:21.478Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-1-78.us-west-2.compute.internal 10.20.1.134:8301
2022-05-14T07:20:01.479Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-1-78.us-west-2.compute.internal 10.20.1.134:8301
2022-05-14T07:22:11.483Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
2022-05-14T07:22:44.550Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
2022-05-14T07:23:17.606Z [INFO]  agent.client.serf.lan: serf: attempting reconnect to ip-10-20-3-189.us-west-2.compute.internal 10.20.3.117:8301
```

ingress gateway error retrieving CA Roots from Consul
```
➜  x fs-tp (main)
     $  kubectl logs consul-ingress-gateway-74c97db57f-bxvlk get-auto-encrypt-client-ca
2022-05-14T07:11:38.468Z [ERROR] Error retrieving CA roots from Consul: err="Get "https://hcpc-cluster-presto.private.consul.328306de-41b8-43a7-9c38-ca8d89d06b07.aws.hashicorp.cloud:443/v1/agent/connect/ca/roots": dial tcp: lookup hcpc-cluster-presto.private.consul.328306de-41b8-43a7-9c38-ca8d89d06b07.aws.hashicorp.cloud on 172.20.0.10:53: read udp 10.20.3.197:39308->172.20.0.10:53: read: connection refused"
```

# Creation of Kubernetes Cluster

Design
-------

The cluster is composed of three nodes, 1 control node and 2 worker nodes, each node has two connected networks. 

- NAT Network on `eth0` for internet access for nodes to pull packages and images, which is the default libvirt network `192.168.122.0/24` 
- Private Network on `eth1` for cross-node communication with static IPs from created subnet `192.168.55.0/24`
- Selected CNI is Cilium 
- Kubernetes Service CIDR remains the default `10.96.0.0/12`
- Kubernetes Pod CIDR remains the default `10.244.0.0/16`
- Since we'll be using `ipam.mode: kubernetes` in cilium, we'll be We're adding the Controller args such that each node has a `/28` length

Before bootstraping the cluster
-------------------------------
Prepare the cluster using the [script](../scripts/before-k8s-bootstrap.sh)


Booststrapping the cluster 
--------------------------
The nodes are bootstrapped using [kubeadm API](https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/).

Configuration files examples are in [Controller Config](./k8s-manifests-examples/k8s-config.yml) & [Worker Config](./k8s-manifests-examples/k8s-join.yml).

Command to bootstrap controller `kubeadm init --config=./k8s-config.yml`.
To generate more tokens `kubeadm token create --print-join-command`
Command to join worker node `kubeadm join --config=./k8s-join.yml`

Make sure to put the correct node name in `nodeRegistration.name` and IP in `nodeRegistration.kubeletExtraArgs: { name: node-ip, value: "<IP>"}` as the attribute of the resources `InitConfiguration` in controller & `JoinConfiguration` in worker node config files.

Installing Cilium
-----------------

Installed cilium via `helm`

First add the repo with `helm repo add cilium https://helm.cilium.io/`

Create the [values file](./helm-values-examples/cilium-values.yml) for cilium installation, keeping in mind the following:

- For a Multi-NIC design, you'll need to set `devices` as your desired devices otherwise cilium will use the first NIC's IP (e.g. eth0 with 192.168.122.252/24) which would conflict with the configuration passed during the bootstrap.

- The `ipam.mode` is set as `kubernetes` since the controller extra args are set and to avoid IP reallocation across cluster reboots.

- The `k8sServiceHost` & `k8sServicePort` should be set otherwise cilium will attempt to connect to the cluster via the default service name/IP (kubernetes.default.svc.cluster.local/10.96.0.1) which will not be usable before the CNI is actually installed.

- Setting the `mtu` value can be highly important as without it cilium will auto-detect the MTU value from the specified NIC interface which does not account for the vxlan header.

After considering the above and any other values deemed important from `helm show values cilium/cilium` or [Cilium Helm Reference](https://docs.cilium.io/en/stable/helm-reference/).

Installation command: `helm install cilium cilium/cilium --version 1.19.2 --namespace kube-system -f ./cilium-values.yml`

Validate the cilium status via `kubectl exec -n kube-system <cilium-pod> -- cilium status`


Example of healthy cilium cluster output

```
[root@ctrl01 ~]# kubectl exec -n kube-system cilium-lrtwc -- cilium status
KVStore:                 Disabled   
Kubernetes:              Ok         1.35 (v1.35.0) [linux/amd64]
Kubernetes APIs:         ["cilium/v2::CiliumCIDRGroup", "cilium/v2::CiliumClusterwideNetworkPolicy", "cilium/v2::CiliumEndpoint", "cilium/v2::CiliumNetworkPolicy", "cilium/v2::CiliumNode", "core/v1::Pods", "networking.k8s.io/v1::NetworkPolicy"]
KubeProxyReplacement:    True   [eth1  192.168.55.11 (Direct Routing)]
Host firewall:           Disabled
SRv6:                    Disabled
CNI Chaining:            none
CNI Config file:         successfully wrote CNI configuration file to /host/etc/cni/net.d/05-cilium.conflist
Cilium:                  Ok   1.19.2 (v1.19.2-3977f6a1)
NodeMonitor:             Listening for events on 2 CPUs with 64x4096 of shared memory
Cilium health daemon:    Ok   
IPAM:                    IPv4: 2/14 allocated from 10.244.0.0/28, 
IPv4 BIG TCP:            Disabled
IPv6 BIG TCP:            Disabled
BandwidthManager:        Disabled
Routing:                 Network: Tunnel [vxlan]   Host: Legacy
Attach Mode:             Legacy TC
Device Mode:             veth
Masquerading:            IPTables [IPv4: Enabled, IPv6: Disabled]
Controller Status:       13/13 healthy
Proxy Status:            OK, ip 10.244.0.5, 0 redirects active on ports 10000-20000, Envoy: external
Global Identity Range:   min 256, max 65535
Hubble:                  Ok              Current/Max Flows: 4095/4095 (100.00%), Flows/s: 0.92   Metrics: Disabled
Encryption:              Disabled        
Cluster health:          3/3 reachable   (2026-04-08T10:11:30Z)   (Probe interval: 1m56.754608943s)
Name                     IP              Node                     Endpoints
Modules Health:          Stopped(23) Degraded(0) OK(74)
```
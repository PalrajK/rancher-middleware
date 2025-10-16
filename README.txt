
HIGH AVAIALBILITY (Kubernetes cluster) Rancher RKE2 IN AWS INSTALLATION STEPS


Terraform is used for Provisioning Pre-Requeties

3 control plane 
3 worker node along with VPC, Subnet, NLB, Security Group with 10250, 10255, 9345, 2379 - 2380, 10256, 8472 and 6443  

Port	Protocol	Used By	Purpose
6443	TCP	Control Plane	Kubernetes API server — used by kubectl, nodes, and components to communicate with the API
9345	TCP	RKE2 Servers	RKE2 cluster coordination and server-to-server communication
2379-2380	TCP	etcd (Control Plane)	etcd client and peer communication — required between all control-plane nodes
10250	TCP	Kubelet (All Nodes)	Secure Kubelet API — used by control plane to get metrics, logs, exec, etc.
10255	TCP	Kubelet (Deprecated)	Read-only Kubelet API — deprecated and often disabled by default
10256	TCP	kube-proxy	Health checks for kube-proxy
8472	UDP	Flannel (CNI)	VXLAN overlay networking between nodes (used by Flannel CNI plugin)

Direction	Source	Port(s)	Purpose
Inbound	Control Plane Nodes	2379–2380, 9345	etcd and RKE2 server communication
Inbound	Worker Nodes	9345	Join cluster via RKE2 server
Inbound	All Nodes (internal)	10250, 10256, 8472	Node-to-node communication
Inbound	Admin IP / Bastion Host	6443	Access Kubernetes API
Inbound	Load Balancer (if used)	6443	External access to API server
Outbound	0.0.0.0/0	All	Allow updates, container pulls, etc.


#ADD IP hostname and FQDN on all three control plane node
 
#Hostname and internal DNS mapping 
10.0.0.205  ip-10-0-0-205  ip-10-0-0-205.ec2.internal 
10.0.1.225  ip-10-0-1-225  ip-10-0-1-225.ec2.internal
10.0.2.121  ip-10-0-2-121  ip-10-0-2-121.ec2.internal



#Cluster Load Balancer DNS name
rke2-nlb-f04fd65c1a351d97.elb.us-east-1.amazonaws.com  (pointing to all three control plane nodes private IPs)


As Inital step we have to start rke2-server and get token which can be used for other nodes to connect to cluster



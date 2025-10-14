
HIGH AVAIALBILITY (Kubernetes cluster) Rancher RKE2 IN AWS INSTALLATION STEPS


Terraform is used for Provisioning Pre-Requeties

3 control plane 
3 worker node along with VPC, Subnet, NLB, Security Group with 10250, 9345, 2379 - 2380 and 6443  

#ADD IP hostname and FQDN on all three control plane node
 
#Hostname and internal DNS mapping 
 
10.0.0.67   ip-10-0-0-67    ip-10-0-0-67.ec2.internal  control-node-1
10.0.1.36   ip-10-0-1-36    ip-10-0-1-36.ec2.internal  control-node-2
10.0.2.224  ip-10-0-2-224   ip-10-0-2-224.ec2.internal  control-node-3


#ADD IP hostname and FQDN on all three worker node
 
#Hostname and internal DNS mapping 
 
10.0.0.100   ip-10-0-0-100   ip-10-0-0-100.ec2.internal  worker-node-1
10.0.1.23    ip-10-0-1-23    ip-10-0-1-23.ec2.internal  worker-node-2
10.0.2.133   ip-10-0-2-133   ip-10-0-2-133.ec2.internal  worker-node-3


#Cluster Load Balancer DNS name
rke2-nlb-f04fd65c1a351d97.elb.us-east-1.amazonaws.com  (pointing to all three control plane nodes private IPs)    10.0.0.67, 10.0.1.36, 10.0.2.224
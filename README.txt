
HIGH AVAIALBILITY (Kubernetes cluster) Rancher RKE2 IN AWS INSTALLATION STEPS


Terraform is used for Provisioning Pre-Requeties

3 control plane 
3 worker node along with VPC, Subnet, NLB, Security Group with 10250, 9345, 2379 - 2380 and 6443  

#ADD IP hostname and FQDN on all three control plane node
 
#Hostname and internal DNS mapping 
10.0.0.205  ip-10-0-0-205  ip-10-0-0-205.ec2.internal 
10.0.1.225  ip-10-0-1-225  ip-10-0-1-225.ec2.internal
10.0.2.121  ip-10-0-2-121  ip-10-0-2-121.ec2.internal



#Cluster Load Balancer DNS name
rke2-nlb-f04fd65c1a351d97.elb.us-east-1.amazonaws.com  (pointing to all three control plane nodes private IPs)    10.0.0.67, 10.0.1.36, 10.0.2.224


As Inital step we have to start rke2-server and get token which can be used for other nodes to connect and then we can alter config.yaml  

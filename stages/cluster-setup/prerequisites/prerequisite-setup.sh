#!/bin/bash

echo "************* Applying e2e-crd *************"
kubectl apply -f utils/e2e-crd.yml

# Cloning oep repository which contains all the test scripts
git clone https://github.com/mayadata-io/oep.git
git checkout script-test

# Setup litmus on the cluster
kubectl apply -f oep/litmus/prerequisite/rbac.yaml
kubectl apply -f oep/litmus/prerequisite/crds.yaml

# creating docker secret
kubectl apply -f oep/litmus/prerequisite/docker-secret.yml -n litmus

echo -e "\n************* Setting up metrics server *************"

# Installing heapster components on the cluster for node monitoring
git clone https://github.com/kubernetes-sigs/metrics-server.git

# Fix "no metrics known for node" error by adding - --kubelet-preferred-address-types=InternalDNS,InternalIP,ExternalDNS,ExternalIP,Hostname
sed -i -e '/args:/ a\          - --kubelet-preferred-address-types=InternalDNS,InternalIP,ExternalDNS,ExternalIP,Hostname \n          - --kubelet-insecure-tls' metrics-server/deploy/kubernetes/metrics-server-deployment.yaml
kubectl apply -f  metrics-server/deploy/kubernetes/
sleep 60

# The below line turns off case sensitive comparison of strings
shopt -s nocasematch

# Check if metrics server is returning output
node_stats=$(kubectl top nodes 2>&1)
while [[ $node_stats == *error* ]]
do
    node_stats=$(kubectl top nodes 2>&1)
    echo "Waiting for metrics server to return top node details"
    sleep 30
done

echo -e "\n************* Top Node Output *************"
kubectl top node

echo -e "\n************* Setting up Director URL configmap *************"
director_url=http://$(kubectl get node -o wide | awk {'print $6'} | head -n 4 | tail -n 1):30380
echo $director_url

# Create configmap for director URL
# Note: Do not change the configmap name config, otherwise update the name in all other playbooks
kubectl create cm config --from-literal=url=$director_url -n litmus

echo -e "\n************* Finished Prerequisites *************"
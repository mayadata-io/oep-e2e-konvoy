#!/bin/bash

echo "************* Applying e2e-crd *************"
kubectl apply -f utils/e2e-crd.yml

# Clone e2e-metrics repo for e2e-metrics stage
git clone https://github.com/mayadata-io/e2e-metrics.git

# Cloning oep-e2e repository which contains all the test scripts
git clone https://github.com/mayadata-io/oep-e2e.git

# Cloning e2e-tests repo for OpenEBS
git clone https://github.com/openebs/e2e-tests.git

# Setup litmus on the cluster
kubectl apply -f oep-e2e/litmus/prerequisite/rbac.yaml
kubectl apply -f oep-e2e/litmus/prerequisite/crds.yaml

# creating docker secret named oep-secret
kubectl apply -f oep-e2e/litmus/prerequisite/docker-secret.yml -n litmus

echo -e "\n************* Setting up metrics server *************"

# Download file
wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml

# Fix "no metrics known for node" error by adding - --kubelet-preferred-address-types=InternalDNS,InternalIP,ExternalDNS,ExternalIP,Hostname
sed -i -e '/args:/ a\          - --kubelet-preferred-address-types=InternalDNS,InternalIP,ExternalDNS,ExternalIP,Hostname \n          - --kubelet-insecure-tls' components.yaml

# Apply metrics-server
kubectl apply -f components.yaml
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

# Store this cm in a file
kubectl get cm -n litmus config -oyaml --export > director_url.txt

echo -e "\n************* Finished Prerequisites *************"

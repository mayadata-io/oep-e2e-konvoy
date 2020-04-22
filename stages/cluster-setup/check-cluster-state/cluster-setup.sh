#!/bin/bash

time="$(TZ=IST date)"
current_time=$time
echo $current_time

echo "***Checking the cluster is Engaged or not***"

state="sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'ls | grep oep-e2e-konvoy'"
cluster_state=$(eval $state)

while [ "${cluster_state}" == "oep-e2e-konvoy" ];
do
  echo "***Cluster is Engaged***"
  cluster_state=$(eval $state)
  sleep 30
done

echo "*** Copy OnPrem cluster config ***"
sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cp -v ~/.kube/config_c1 ~/.kube/config'

echo "*************************Checking the Cluster's Health********************"

# ssh into the deployer machine and check number of ready nodes
echo "***************Checking for the number of nodes in ready state***************"
ready_nodes=$(sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port kubectl get nodes --no-headers | grep -v NotReady | wc -l)

if [ "$ready_nodes" -eq 6 ];
then
  echo "Number of nodes in ready state is $ready_nodes"
  echo "******Cluster is in Healthy state******"
  
  echo "*************Dumping cluster state*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port kubectl get nodes
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port kubectl get pod --all-namespaces

  echo "*************Cloning oep-e2e-konvoy repo*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'git clone -b oep-release https://github.com/mayadata-io/oep-e2e-konvoy.git'
  #####################################
  ##          Prerequisites          ##
  #####################################

  echo "************* Running Prerequisites *************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && chmod 755 ./stages/cluster-setup/prerequisites/prerequisite-setup.sh && ./stages/cluster-setup/prerequisites/prerequisite-setup.sh'

else
  echo "All nodes are not ready"
  echo -e "Number of nodes in ready state: $ready_nodes"
  echo -e "\nCluster State: Not Healthy\n"
  exit 1;
fi
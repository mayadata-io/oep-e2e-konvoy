#!/bin/bash
set -x

pod() {
  echo "*************Cleaning up the cluster*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/cluster-tear-down/cluster-cleanup.sh node '"'$master_name'"' '"'$worker1_name'"' '"'$worker2_name'"' '"'$worker3_name'"'' '"'$worker4_name'"' '"'$worker5_name'"'
}

node() {
  bash utils/pooling jobname:e2e-metrics
  bash utils/e2e-cr jobname:cluster-cleanup jobphase:Running
  
  master_name=$(echo $1)
  worker1_name=$(echo $2)
  worker2_name=$(echo $3)
  worker3_name=$(echo $4)
  worker4_name=$(echo $5)
  worker5_name=$(echo $6)
  
  git clone https://github.com/mayadata-io/litmus.git
  cd litmus
  
  # Replace the VM names in CSV file
  sed -i -e "s/auto1/$master_name/g" \
  -e "s/auto2/$worker1_name/g" \
  -e "s/auto3/$worker2_name/g" \
  -e "s/auto4/$worker3_name/g" k8s/on-prem/openshift-installer/vm_name.csv
  
  sed -i "/$worker3_name/a \
  $worker4_name \
  $worker5_name" k8s/on-prem/openshift-installer/vm_name.csv
  
  # Replace the snapshot name and esx ip in vars
  sed -i -e 's/snapshot_name: "oc-cluster"/snapshot_name: "initial-setup"/g' \
  -e 's/esx_ip: "10.12.1.1"/esx_ip: "10.43.1.1"/g' k8s/on-prem/openshift-installer/vars.yml
  
  ansible-playbook k8s/on-prem/openshift-installer/revert_cluster_state.yml -v
  
  # Removing oep-e2e-konvoy repo
  cd && rm -rf oep-e2e-konvoy
}

if [ "$1" == "node" ];then
  node $2 $3 $4 $5 $6 $7
else
  pod
fi
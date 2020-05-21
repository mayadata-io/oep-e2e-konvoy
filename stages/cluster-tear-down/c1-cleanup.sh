#!/bin/bash
set -x

pod() {
  echo "*************Cleaning up the cluster*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/cluster-tear-down/cluster-cleanup.sh node '"'$c1_master1_name'"' '"'$c1_worker1_name'"' '"'$c1_worker2_name'"' '"'$c1_worker3_name'"' '"'$c1_worker4_name'"' '"'$c1_worker5_name'"' '"'$C1_ESX_IP'"' '"'$C1_SNAPSHOT_NAME'"''
}

node() {
  bash utils/pooling jobname:e2e-metrics
  bash utils/e2e-cr jobname:cluster-cleanup jobphase:Running

  c1_master1_name=$(echo $1)
  c1_worker1_name=$(echo $2)
  c1_worker2_name=$(echo $3)
  c1_worker3_name=$(echo $4)
  c1_worker4_name=$(echo $5)
  c1_worker5_name=$(echo $6)
  C1_ESX_IP=$(echo $7)
  C1_SNAPSHOT_NAME=$(echo $8)

  git clone https://github.com/mayadata-io/litmus.git

  # Replace the VM names in CSV file
  sed -i -e "s/auto1/$c1_master1_name/g" \
  -e "s/auto2/$c1_worker1_name/g" \
  -e "s/auto3/$c1_worker2_name/g" \
  -e "s/auto4/$c1_worker3_name/g" litmus/k8s/on-prem/openshift-installer/vm_name.csv

  sed -i -e "/$c1_worker3_name/a \
  $c1_worker4_name\n$c1_worker5_name" litmus/k8s/on-prem/openshift-installer/vm_name.csv

  # Replace the snapshot name and esx ip in vars
  sed -i -e 's/snapshot_name: "oc-cluster"/snapshot_name: "'$C1_SNAPSHOT_NAME'"/g' \
  -e 's/esx_ip: "10.12.1.1"/esx_ip: "'$C1_ESX_IP'"/g' litmus/k8s/on-prem/openshift-installer/vars.yml

  ansible-playbook litmus/k8s/on-prem/openshift-installer/revert_cluster_state.yml -v


  # Wait for cluster2 to revert to its latest snapshot
  echo -e "\nWaiting for cluster2 to revert to its latest snapshot\n"
  sleep 120

  # Removing oep-e2e-konvoy repo
  cd && rm -rf oep-e2e-konvoy
}

if [ "$1" == "node" ];then
  node $2 $3 $4 $5 $6 $7 $8 $9
else
  pod
fi

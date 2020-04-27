#!/bin/bash
set -x

pod() {
  echo "*************Cleaning up the connected cluster*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/cluster-tear-down/c2-cleanup.sh node '"'$c2_master1_name'"' '"'$c2_worker1_name'"' '"'$c2_worker2_name'"' '"'$c2_worker3_name'"' '"'$c2_worker4_name'"' '"'$c2_worker5_name'"' '"'$C2_ESX_IP'"' '"'$C2_SNAPSHOT_NAME'"''
}

node() {
  # Assigning values to cluster2 variables
  c2_master1_name=$(echo $1)
  c2_worker1_name=$(echo $2)
  c2_worker2_name=$(echo $3)
  c2_worker3_name=$(echo $4)
  c2_worker4_name=$(echo $5)
  c2_worker5_name=$(echo $6)
  C2_ESX_IP=$(echo $7)
  C2_SNAPSHOT_NAME=$(echo $8)

  git clone https://github.com/openebs/e2e-tests.git

  # Replace the VM names in CSV file
  sed -i -e "s/auto1/$c2_master1_name/g" \
  -e "s/auto2/$c2_worker1_name/g" \
  -e "s/auto3/$c2_worker2_name/g" \
  -e "s/auto4/$c2_worker3_name/g" e2e-tests/k8s/on-prem/openshift-installer/vm_name.csv

  sed -i -e "/$c2_worker3_name/a \
  $c2_worker4_name\n$c2_worker5_name" e2e-tests/k8s/on-prem/openshift-installer/vm_name.csv

  # Replace the snapshot name and esx ip in vars
  sed -i -e 's/snapshot_name: "oc-cluster"/snapshot_name: "'$C2_SNAPSHOT_NAME'"/g' \
  -e 's/esx_ip: "10.12.1.1"/esx_ip: "'$C2_ESX_IP'"/g' e2e-tests/k8s/on-prem/openshift-installer/vars.yml

  ansible-playbook e2e-tests/k8s/on-prem/openshift-installer/revert_cluster_state.yml -v

  ## Add sleep so that the VM's are ready
  sleep 10
}

if [ "$1" == "node" ];then
  node $2 $3 $4 $5 $6 $7 $8 $9
else
  pod
fi

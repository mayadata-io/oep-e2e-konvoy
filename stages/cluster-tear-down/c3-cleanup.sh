#!/bin/bash
set -x

pod() {
  echo "*************Cleaning up the connected cluster*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/cluster-tear-down/c3-cleanup.sh node '"'$c3_master1_name'"' '"'$c3_worker1_name'"' '"'$c3_worker2_name'"' '"'$c3_worker3_name'"' '"'$c3_worker4_name'"' '"'$c3_worker5_name'"' '"'$C3_ESX_IP'"' '"'$C3_SNAPSHOT_NAME'"' '"'$C3_VM_PASS'"' '"'$VM_USER'"' '"'$C3_VM1_IP'"' '"'$C3_VM2_IP'"' '"'$C3_VM3_IP'"' '"'$C3_VM4_IP'"' '"'$C3_VM5_IP'"' '"'$C3_VM6_IP'"' '"'$C3_ESX_IP'"''
}

node() {
  # Assigning values to cluster3 variables
  c3_master1_name=$(echo $1)
  c3_worker1_name=$(echo $2)
  c3_worker2_name=$(echo $3)
  c3_worker3_name=$(echo $4)
  c3_worker4_name=$(echo $5)
  c3_worker5_name=$(echo $6)
  C3_ESX_IP=$(echo $7)
  C3_SNAPSHOT_NAME=$(echo $8)
  C3_VM_PASS=$9
  VM_USER=${10}
  C3_VM1_IP=${11}
  C3_VM2_IP=${12}
  C3_VM3_IP=${13}
  C3_VM4_IP=${14}
  C3_VM5_IP=${15}
  C3_VM6_IP=${16}

  # Make a separate dir for C3 to save from conflict during cluster-revert process
  mkdir c3-cleanup && cd c3-cleanup

  git clone https://github.com/openebs/e2e-tests.git

  # Replace the VM names in CSV file
  sed -i -e "s/auto1/$c3_master1_name/g" \
  -e "s/auto2/$c3_worker1_name/g" \
  -e "s/auto3/$c3_worker2_name/g" \
  -e "s/auto4/$c3_worker3_name/g" e2e-tests/k8s/on-prem/openshift-installer/vm_name.csv

  sed -i -e "/$c3_worker3_name/a \
  $c3_worker4_name\n$c3_worker5_name" e2e-tests/k8s/on-prem/openshift-installer/vm_name.csv

  # Replace the snapshot name and esx ip in vars
  sed -i -e 's/snapshot_name: "oc-cluster"/snapshot_name: "'$C3_SNAPSHOT_NAME'"/g' \
  -e 's/esx_ip: "10.12.1.1"/esx_ip: "'$C3_ESX_IP'"/g' e2e-tests/k8s/on-prem/openshift-installer/vars.yml

  ansible-playbook e2e-tests/k8s/on-prem/openshift-installer/revert_cluster_state.yml -v

  ## Add sleep so that the VM's are ready
  sleep 10

  echo -e "\n[ Rebooting the VM's ]-------------------------------------------\n"
  echo "Rebooting VM : $C3_VM1_IP"
  sshpass -p $C3_VM_PASS ssh $VM_USER@$C3_VM1_IP 'reboot' > /dev/null 2>&1 &
  sleep 5
  echo "Rebooting VM : $C3_VM2_IP"
  sshpass -p $C3_VM_PASS ssh $VM_USER@$C3_VM2_IP 'reboot' > /dev/null 2>&1 &
  sleep 5
  echo "Rebooting VM : $C3_VM3_IP"
  sshpass -p $C3_VM_PASS ssh $VM_USER@$C3_VM3_IP 'reboot' > /dev/null 2>&1 &
  sleep 5
  echo "Rebooting VM : $C3_VM4_IP"
  sshpass -p $C3_VM_PASS ssh $VM_USER@$C3_VM4_IP 'reboot' > /dev/null 2>&1 &
  sleep 5
  echo "Rebooting VM : $C3_VM5_IP"
  sshpass -p $C3_VM_PASS ssh $VM_USER@$C3_VM5_IP 'reboot' > /dev/null 2>&1 &
  sleep 5
  echo "Rebooting VM : $C3_VM6_IP"
  sshpass -p $C3_VM_PASS ssh $VM_USER@$C3_VM6_IP 'reboot' > /dev/null 2>&1 &

}

if [ "$1" == "node" ];then
  node $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14} ${15} ${16} ${17}
else
  pod
fi

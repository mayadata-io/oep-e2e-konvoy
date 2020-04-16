#!/bin/bash

set -e
pod() {
  echo "*************Create api-key check*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/functional-testing-with-rest/cluster-connect-check.sh node'
}

node() {
  
bash utils/pooling jobname:create-apikey-check
bash utils/e2e-cr jobname:trrc01-cluster-connect-check jobphase:Running 

# git clone https://$username:$password@github.com/mayadata-io/oep-e2e.git
echo "Connect new cluster -------------------------------------------------"
kubectl create -f oep-e2e/litmus/director/cluster-connect/run_litmus_test.yml

test_name=cluster-connect
echo $test_name

litmus_pod=$(kubectl get po -n litmus | grep $test_name  | awk {'print $1'} | tail -n 1)
echo $litmus_pod

job_status=$(kubectl get po  $litmus_pod -n litmus | awk {'print $3'} | tail -n 1)
while [[ "$job_status" != "Completed" ]]
do 
    job_status=$(kubectl get po  $litmus_pod -n litmus | awk {'print $3'} | tail -n 1)
    sleep 6
done

kubectl logs -f $litmus_pod -n litmus

testResult=$(kubectl get litmusresult ${test_name} --no-headers -o custom-columns=:spec.testStatus.result)
echo $testResult

if [ "$testResult" != Pass ]
then 
    exit 1; 
else
    bash utils/e2e-cr jobname:trrc01-cluster-connect-check jobphase:Completed
fi
}

if [ "$1" == "node" ];then
  node
else
  pod
fi

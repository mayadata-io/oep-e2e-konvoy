#!/bin/bash

pod() {
  echo "*************Self cluster connect check*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/functional-testing-with-rest/cluster-connect-checks/self-connect-cluster-check.sh node'
}

node() {
  ######################
  ##   Running test  ##
  ######################

  echo "Fetching Administrator secrets of self connected cluster---------------"
  test_name=create-admininstator-secret-check
  echo -e "\n Test Name: $test_name"

  kubectl get pods
  kubectl create -f oep-e2e/litmus/director/admin-create-apikey/run_litmus_test.yml
  
  # check litmus test result
  litmus_pod=$(kubectl get po -n litmus | grep $test_name  | awk {'print $1'} | tail -n 1)
  echo -e "\n Litmus Pod name: $litmus_pod"

  job_status=$(kubectl get po  $litmus_pod -n litmus | awk {'print $3'} | tail -n 1)
  while [[ "$job_status" != "Completed" ]]
  do 
    job_status=$(kubectl get po  $litmus_pod -n litmus | awk {'print $3'} | tail -n 1)
    echo "Waiting for job status to be Completed..."
    sleep 6
  done
  
  echo -e "\nLitmus pod logs: "
  kubectl logs -f $litmus_pod -n litmus
  
  testResult=$(kubectl get litmusresult ${test_name} --no-headers -o custom-columns=:spec.testStatus.result)
  echo $testResult

  if [ "$testResult" != Pass ]; then 
  exit 1; 
  fi

  echo -e "\n ClusterId and GroupId for self connect cluster----------------"
  test_name=self-connect-cluster-check
  echo -e "\n Test Name: $test_name"

  kubectl get pods
  
  kubectl create -f oep-e2e/litmus/director/self-cluster-connect/run_litmus_test.yml
  
  # check litmus test result
  litmus_pod=$(kubectl get po -n litmus | grep $test_name  | awk {'print $1'} | tail -n 1)
  echo -e "\n Litmus Pod name: $litmus_pod"

  job_status=$(kubectl get po  $litmus_pod -n litmus | awk {'print $3'} | tail -n 1)

  while [[ "$job_status" != "Completed" ]]
  do 
    job_status=$(kubectl get po  $litmus_pod -n litmus | awk {'print $3'} | tail -n 1)
    echo "Waiting for job status to be Completed..."
    sleep 6
  done

  echo -e "\nLitmus pod logs: "

  kubectl logs -f $litmus_pod -n litmus

  testResult=$(kubectl get litmusresult ${test_name} --no-headers -o custom-columns=:spec.testStatus.result)
  echo $testResult

  if [ "$testResult" != Pass ]; then
  exit 1;
  fi
}

if [ "$1" == "node" ];then
  node
else
  pod
fi

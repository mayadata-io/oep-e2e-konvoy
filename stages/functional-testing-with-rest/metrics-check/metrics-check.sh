#!/bin/bash

pod() {
  echo "*************Metrics check*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/functional-testing-with-rest/metrics-check/metrics-check.sh node'
}

node() {
  # Job sequencing
  bash utils/pooling jobname:client-components-check
  bash utils/e2e-cr jobname:metrics-check jobphase:Running

  # Use user's cluster kube-config
  echo -e "Use kubeconfig of cluster2\n"
  export KUBECONFIG=~/.kube/config_c2

  # Verify current context
  kubectl config current-context

  # This line has been added in the first check(create-apikey-check)
  #kubectl create clusterrolebinding upgrade-admin --clusterrole cluster-admin --serviceaccount=litmus:litmus

  echo -e "\nList pods in openebs namespace: "
  kubectl get po -n openebs

  ######################
  ##   Running test   ##
  ######################

  # This line has been added in the first check(create-apikey-check)
  #echo "Fetching director admin credentials for the following test----------------"
  #kubectl create -f oep-e2e/litmus/director/admin-secret/run_litmus_test.yml

  test_name=fetch-unique-id-check
  echo $test_name

  litmus_pod=$(kubectl get po -n litmus | grep $test_name  | awk {'print $1'} | tail -n 1)
  echo $litmus_pod

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

  echo "Fetching metrics by querying cortex-agent----------------"
  kubectl create -f oep-e2e/litmus/director/metrics/run_litmus_test.yml

  test_name=metrics-check
  echo $test_name

  litmus_pod=$(kubectl get po -n litmus | grep $test_name  | awk {'print $1'} | tail -n 1)
  echo $litmus_pod

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
  else
    export KUBECONFIG=~/.kube/config_c1
    bash utils/e2e-cr jobname:metrics-check jobphase:Completed
  fi
}

if [ "$1" == "node" ];then
  node
else
  pod
fi

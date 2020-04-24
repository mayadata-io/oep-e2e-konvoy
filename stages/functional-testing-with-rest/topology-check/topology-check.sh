#!/bin/bash

pod() {
  echo "*************Cluster connect check*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/functional-testing-with-rest/topology-check/topology-check.sh node'
}

node() {
  # Use user's cluster kube-config
  echo -e "Use kubeconfig of cluster2\n"
  export KUBECONFIG=~/.kube/config_user

  # Verify current context
  kubectl config current-context

  ######################
  ##   Running test   ##
  ######################

  echo "Run topology test to fetch cluster namespaces----------------"
  kubectl create -f oep-e2e/litmus/director/topology/run_litmus_test.yml

  test_name=topology-check
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
}


if [ "$1" == "node" ];then
  node
else
  pod
fi

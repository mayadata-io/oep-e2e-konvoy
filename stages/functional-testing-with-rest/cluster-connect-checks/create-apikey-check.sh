#!/bin/bash

pod() {
  echo "*************Create api-key check*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/functional-testing-with-rest/cluster-connect-checks/create-apikey-check.sh node'
}

node() {
  # Copy user's cluster kube-config
  cp -v ~/.kube/config_user ~/.kube/config 

  # Check current context
  kubectl config current-context

  # Setup litmus on the cluster
  kubectl apply -f oep-e2e/litmus/prerequisite/rbac.yaml
  kubectl apply -f oep-e2e/litmus/prerequisite/crds.yaml

  # Applying e2e-CRD
  echo "***Applying e2e-crd***********"
  kubectl apply -f utils/e2e-crd.yml

  bash utils/e2e-cr jobname:create-apikey-check jobphase:Waiting
  bash utils/e2e-cr jobname:create-apikey-check jobphase:Running 
  bash utils/e2e-cr jobname:trrc01-cluster-connect-check jobphase:Waiting
  bash utils/e2e-cr jobname:client-components-check jobphase:Waiting

  echo "Create new api key for new user account in director onprem -------------------------------------------------"
  kubectl create -f oep-e2e/litmus/director/create-apikey/run_litmus_test.yml

  test_name=create-apikey-check
  echo $test_name

  litmus_pod=$(kubectl get po -n litmus | grep $test_name  | awk {'print $1'} | tail -n 1)
  echo $litmus_pod

  # Check completed status for job
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

  if [ "$testResult" != Pass ]
  then
    exit 1;
  else
    # saving secret yaml into a file
    kubectl get secret director-user-pass -n litmus -oyaml > secret.yaml

    # changing config to director cluster
    cp  .kube/config_onprem ~/.kube/config

    # creating director-user-pass secret in director cluster
    kubectl create -f secret.yaml -n litmus
    kubectl get secret -n litmus

    bash utils/e2e-cr jobname:create-apikey-check jobphase:Completed
  fi
}

if [ "$1" == "node" ];then
  node
else
  pod
fi

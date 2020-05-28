#!/bin/bash

pod() {
  echo "*************Create api-key check*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/functional-testing-with-rest/cluster-connect-checks/create-apikey-check.sh node'
}

node() {
  # Job Sequencing
  bash utils/e2e-cr jobname:create-apikey-check jobphase:Waiting
  bash utils/e2e-cr jobname:create-apikey-check jobphase:Running
  bash utils/e2e-cr jobname:trrc01-cluster-connect-check jobphase:Waiting
  bash utils/e2e-cr jobname:trrc01-cluster3-connect jobphase:Waiting
  bash utils/e2e-cr jobname:client-components-check jobphase:Waiting
  bash utils/e2e-cr jobname:client3-components-check jobphase:Waiting
  # bash utils/e2e-cr jobname:metrics-check jobphase:Waiting


  # Use user's cluster kube-config
  echo -e "Use kubeconfig of cluster2\n"
  export KUBECONFIG=~/.kube/config_c2

  # Verify current context
  kubectl config current-context

  # Apply pre-requisites
  echo -e "\n[ Applying pre-requisites ]-------------------------------------------------\n"

  echo "************* Applying e2e-crd *************"
  kubectl apply -f utils/e2e-crd.yml

  # Setup litmus on the cluster
  echo -e "\n[ Setting up Litmus ]-----------------------------\n"
  kubectl apply -f oep-e2e/litmus/prerequisite/rbac.yaml
  kubectl apply -f oep-e2e/litmus/prerequisite/crds.yaml

  kubectl create clusterrolebinding upgrade-admin --clusterrole cluster-admin --serviceaccount=litmus:litmus

  echo "Fetching director admin credentials for further test (metrics check and topology check)----------------"
  kubectl create -f oep-e2e/litmus/director/admin-secret/run_litmus_test.yml

  # Creating docker secret named oep-secret
  kubectl apply -f oep-e2e/litmus/prerequisite/docker-secret.yml -n litmus

  # Create config configmap from  director_url.txt
  kubectl apply -f director_url.txt -n litmus

  # Wait for the resources to show up
  echo -e "\nWaiting for the litmus resources to show up\n"
  sleep 10

  echo "Create new api key for new user account in director c1 ------------------------"
  kubectl create -f oep-e2e/litmus/director/create-apikey/run_litmus_test.yml

  test_name=create-apikey-check
  echo -e "\nTest Name: $test_name\n"

  litmus_pod=$(kubectl get po -n litmus | grep $test_name  | awk {'print $1'} | tail -n 1)
  echo -e "\nLitmus Pod name: $litmus_pod"

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
  echo -e "\nTest Result: $testResult\n"

  if [ "$testResult" != Pass ]
  then
    export KUBECONFIG=~/.kube/config_c1
    bash utils/e2e-cr jobname:create-apikey jobphase:Completed
    exit 1;
  else
    # Saving secret yaml into a file
    kubectl get secret director-user-pass -n litmus -oyaml > secret.yaml

    # Changing config to director cluster
    export KUBECONFIG=~/.kube/config_c1

    # Creating director-user-pass secret in director cluster
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

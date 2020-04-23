#!/bin/bash

pod() {
  echo "*************Create api-key check*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/functional-testing-with-rest/cluster-connect-checks/create-apikey-check.sh node'
}

node() {
  # Use user's cluster kube-config
  echo -e "Use kubeconfig of cluster2\n"
  export KUBECONFIG=~/.kube/config_user

  # Verify current context
  kubectl config current-context

  # Setup litmus on the cluster
  kubectl apply -f oep-e2e/litmus/prerequisite/rbac.yaml
  kubectl apply -f oep-e2e/litmus/prerequisite/crds.yaml

  # Creating docker secret named oep-secret
  kubectl apply -f oep-e2e/litmus/prerequisite/docker-secret.yml -n litmus

  # Create config configmap from  director_url.txt
  kubectl apply -f director_url.txt -n litmus


  # Applying e2e-CRD
  echo "***Applying e2e-crd***********"
  kubectl apply -f utils/e2e-crd.yml

  bash utils/e2e-cr jobname:create-apikey-check jobphase:Waiting
  bash utils/e2e-cr jobname:create-apikey-check jobphase:Running 
  bash utils/e2e-cr jobname:trrc01-cluster-connect-check jobphase:Waiting
  bash utils/e2e-cr jobname:client-components-check jobphase:Waiting
  bash utils/e2e-cr jobname:metrics-check jobphase:Waiting


  echo "Create new api key for new user account in director onprem ------------------------"
  kubectl create -f oep-e2e/litmus/director/create-apikey/run_litmus_test.yml

  echo -e "\n************* Setting up metrics server *************"

  # Download file
  wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml

  # Fix "no metrics known for node" error by adding - --kubelet-preferred-address-types=InternalDNS,InternalIP,ExternalDNS,ExternalIP,Hostname
  sed -i -e '/args:/ a\          - --kubelet-preferred-address-types=InternalDNS,InternalIP,ExternalDNS,ExternalIP,Hostname \n          - --kubelet-insecure-tls' components.yaml

  # Apply metrics-server
  kubectl apply -f components.yaml
  sleep 60

  # The below line turns off case sensitive comparison of strings
  shopt -s nocasematch

  # Check if metrics server is returning output
  node_stats=$(kubectl top nodes 2>&1)
  while [[ $node_stats == *error* ]]
  do
    node_stats=$(kubectl top nodes 2>&1)
    echo "Waiting for metrics server to return top node details"
    sleep 30
  done

  echo -e "\n************* Top Node Output *************"
  kubectl top node
  ######################## metrics-server setup done

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
    bash utils/e2e-cr jobname:create-apikey-check jobphase:Completed

    # Saving secret yaml into a file
    kubectl get secret director-user-pass -n litmus -oyaml > secret.yaml

    # Changing config to director cluster
    export KUBECONFIG=~/.kube/config_onprem

    # Creating director-user-pass secret in director cluster
    kubectl create -f secret.yaml -n litmus
    kubectl get secret -n litmus

    # Switch back to user cluster config for next dependent jobs to proceed
    export KUBECONFIG=~/.kube/config_user

  fi
}

if [ "$1" == "node" ];then
  node
else
  pod
fi

#!/bin/bash

pod() {
  ## Creating Cstor pool using DOP on cluster2
  echo -e "\n************************ Creating Cstor pool ******************************************\n"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/openebs-install/TCID-DIR-OP-CSTOR-POOL-RECOMMEND-CREATE-STRIPE.sh node'
}

node() {

  # Use user's cluster kube-config
  echo -e "Use kubeconfig of cluster2\n"
  export KUBECONFIG=~/.kube/config_c2

  # Verify current context
  kubectl config current-context

  bash utils/pooling jobname:tcid-iuoi02-openebs-install
  bash utils/e2e-cr jobname:tcid-dir-op-cstor-pool-recommend-create-stripe jobphase:Running

  kubectl create -f oep-e2e/litmus/director/TCID-DIR-OP-CSTOR-POOL-RECOMMEND-CREATE-STRIPE/run_litmus_test.yml
  echo -e "\nPods in litmus namespace:\n"
  kubectl get pods -n litmus 

  test_name=create-cstor-pool
  echo -e "\nTest Name: $test_name\n"

  litmus_pod=$(kubectl get po -n litmus | grep $test_name  | awk {'print $1'} | tail -n 1)
  echo -e "\nLitmus Pod name: $litmus_pod"

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
    # export KUBECONFIG=~/.kube/config_c1
    bash utils/e2e-cr jobname:tcid-dir-op-cstor-pool-recommend-create-stripe jobphase:Completed
    exit 1;
  else
    # export KUBECONFIG=~/.kube/config_c1
    bash utils/e2e-cr jobname:tcid-dir-op-cstor-pool-recommend-create-stripe jobphase:Completed
  fi

}

if [ "$1" == "node" ];then
  node
else
  pod
fi
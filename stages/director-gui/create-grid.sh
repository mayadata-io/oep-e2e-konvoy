#!/bin/bash

pod() {
  echo -e "\n*************Setting up Selenium Grid****************\n"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/director-gui/create-grid.sh node '"'$CI_PIPELINE_ID'"''
}

node() {
  bash utils/e2e-cr jobname:selenium-grid-deploy jobphase:Waiting
  bash utils/e2e-cr jobname:selenium-grid-deploy jobphase:Running
  bash utils/e2e-cr jobname:selenium-grid-cleanup jobphase:Waiting

  PIPELINE_ID=$1

  path=$(pwd)

  echo -e "\n[ Cloning gui-automation repo ] ------------------------------------\n"
  git clone https://github.com/mayadata-io/gui-automation.git
  cd gui-automation
  tests_count=`find . -type f -name '*_test.py' -exec grep -e 'def test_' '{}' \; | wc -l`
  echo "Number of GUI test scripts: $tests_count"
  cd ..

  cd stages/director-gui/templates
  ls
  cluster1=$(echo "pipeline-$PIPELINE_ID")

  echo -e "\n[ Creating selenium stack ] ----------------------------------------\n"
  aws cloudformation create-stack --stack-name konvoy-selenium-grid-${cluster1} --template-body file://hub.yml --parameters ParameterKey=NumberOfChromeNodes,ParameterValue=$tests_count ParameterKey=ClusterName,ParameterValue=${cluster1} ParameterKey=LogName,ParameterValue=${cluster1}

  cd ../../..
  bash utils/e2e-cr jobname:selenium-grid-deploy jobphase:Completed
}

if [ "$1" == "node" ];then
  node $2
else
  pod
fi
#!/bin/bash

pod() {
  echo -e "\n*************Setting up Selenium Grid****************\n"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/director-gui/create-grid.sh node '"'$CI_PROJECT_NAME'"' '"'$CI_PIPELINE_ID'"''
}

node() {
  bash utils/e2e-cr jobname:selenium-grid-deploy jobphase:Waiting
  bash utils/e2e-cr jobname:selenium-grid-deploy jobphase:Running
  bash utils/e2e-cr jobname:tcid-gaau01-gui-auth jobphase:Waiting
  bash utils/e2e-cr jobname:tcid-gacc01-gui-cluster jobphase:Waiting
  bash utils/e2e-cr jobname:tcid-gada01-gui-dashboard-home jobphase:Waiting
  bash utils/e2e-cr jobname:tcid-gato01-gui-dashboard-topology jobphase:Waiting
  bash utils/e2e-cr jobname:gui-dashboard jobphase:Waiting
  bash utils/e2e-cr jobname:tcid-gaal01-gui-dashboard-alerts jobphase:Waiting
  bash utils/e2e-cr jobname:tcid-galo01-gui-dashboard-logs jobphase:Waiting
  bash utils/e2e-cr jobname:tcid-gada02-gui-dashboard-overview jobphase:Waiting

  CI_PROJECT_NAME=$(echo $1)
  CI_PIPELINE_ID=$(echo $2)
  GUID=grid-${CI_PROJECT_NAME}-${CI_PIPELINE_ID}
  path=$(pwd)

  echo -e "\n[ Cloning gui-automation repo ] ------------------------------------\n"
  git clone https://github.com/mayadata-io/gui-automation.git
  cd gui-automation
  #tests_count=`find . -type f -name '*_test.py' -exec grep -e 'def test_' '{}' \; | wc -l`
  tests_count=25
  echo "Number of GUI test scripts: $tests_count"
  cd ..

  cd stages/director-gui/templates

  echo -e "\n[ Creating selenium stack ] ----------------------------------------\n"
  aws cloudformation create-stack --stack-name ${GUID} --template-body file://hub.yml --parameters ParameterKey=NumberOfChromeNodes,ParameterValue=$tests_count ParameterKey=ClusterName,ParameterValue=${GUID} ParameterKey=LogName,ParameterValue=${GUID}

  cd ../../..
  bash utils/e2e-cr jobname:selenium-grid-deploy jobphase:Completed
}

if [ "$1" == "node" ];then
  node $2 $3
else
  pod
fi

#!/bin/bash

set -e
pod() {
  ## Installing OpenEBS using DOP on cluster2
  echo -e "\n*************Cleaning up Selenium Grid****************\n"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/selenium-grid/delete-grid.sh node '"'$CI_PIPELINE_ID'"''
}

node() {

  bash utils/pooling jobname:selenium-grid-deploy
  bash utils/e2e-cr jobname:selenium-grid-cleanup jobphase:Running

  PIPELINE_ID=$1

  {
    cluster1=$(echo "pipeline-$PIPELINE_ID")
    aws cloudformation delete-stack --stack-name selenium-grid-${cluster1}
  } || {
    echo 'Selenium CloudFormation stack was absent'
  }

  bash utils/e2e-cr jobname:selenium-grid-cleanup jobphase:Completed
}

if [ "$1" == "node" ];then
  node $2
else
  pod
fi
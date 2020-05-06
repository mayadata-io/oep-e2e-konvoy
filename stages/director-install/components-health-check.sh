#!/bin/bash

# Sequencing Jobs
# bash utils/pooling jobname:dop-deploy
# bash utils/e2e-cr jobname:components-health-check jobphase:Running

echo -e "\n************************ Running basic-sanity tests ***********************************\n"
bash oep-e2e/scripts/director-health-check.sh

  # Replace namespace for ingress-nginx check
  sed -i 's/value: ingress-nginx/value: default/g' oep-e2e/litmus/director/ingress-nginx/run_litmus_test.yml

  echo -e "\n************************ Running basic-sanity tests ***********************************\n"
  bash oep-e2e/scripts/director-health-check.sh

  bash utils/e2e-cr jobname:components-health-check jobphase:Completed

  # If any of the above check fails, then fail this job
  if [ $(cat result.txt | grep -ic fail) != 0 ];then
    exit 1
  fi
}

if [ "$1" == "node" ];then
  node
else
  pod
fi

#!/bin/bash

# Sequencing Jobs
# bash utils/pooling jobname:dop-deploy
# bash utils/e2e-cr jobname:components-health-check jobphase:Running

echo -e "\n************************ Running basic-sanity tests ***********************************\n"
bash oep-e2e/scripts/director-health-check.sh

# bash utils/e2e-cr jobname:components-health-check jobphase:Completed

# If any of the above check fails, then fail this job
if [ $(cat result.txt | grep -ic fail) != 0 ];then
  exit 1
fi

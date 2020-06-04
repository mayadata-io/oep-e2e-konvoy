#!/bin/bash

echo -e "\n************************ Running basic-sanity tests ***********************************\n"
bash oep-e2e/scripts/director-health-check.sh

# If any of the above check fails, then fail this job
if [ $(cat result.txt | grep -ic fail) != 0 ];then
  exit 1
fi


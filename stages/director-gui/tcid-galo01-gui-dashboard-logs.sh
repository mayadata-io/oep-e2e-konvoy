#!/bin/bash

pod() {

## Running gui-dashboard-logs test
echo -e "\n************************ Running GUI dashboard-logs test ******************************\n"
sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/director-gui/tcid-galo01-gui-dashboard-logs.sh node '"'$CI_PROJECT_NAME'"' '"'$CI_PIPELINE_ID'"''
}

node() {

bash utils/pooling jobname:selenium-grid-deploy
bash utils/e2e-cr jobname:tcid-galo01-gui-dashboard-logs jobphase:Running

URL=$(kubectl get cm -n litmus config -o=jsonpath="{.items}{.data.url}")
echo -e "\nDOP URL: $URL\n"

CI_PROJECT_NAME=$(echo $1)
CI_PIPELINE_ID=$(echo $2)
GUID=grid-${CI_PROJECT_NAME}-${CI_PIPELINE_ID}

output=`aws cloudformation describe-stacks --stack-name $GUID --query Stacks[].Outputs[].OutputValue | sed -r 's/"+//g'`
grid=`echo $output | awk {'print $2'}`

cd gui-automation

######################
##   Running test  ##
######################

python3.7 -m pip install -r requirements.txt

#Running tests with galo01 marker
python3.7 -m pytest -m galo01 --url $URL --environment remote --hub $grid -v --tests-per-worker 10 --reruns 1 --html=./results/report.html

cd ..

bash utils/e2e-cr jobname:tcid-galo01-gui-dashboard-logs jobphase:Completed
}

if [ "$1" == "node" ];then
  node $2 $3
else
  pod
fi
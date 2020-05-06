#!/bin/bash

pod() {

## Running gui-auth test
echo -e "\n************************ Running GUI auth test ****************************************\n"
sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-rancher && bash stages/director-gui/tcid-gaau01-gui-auth.sh node'
}

node() {

bash utils/pooling jobname:selenium-grid-deploy
bash utils/e2e-cr jobname:tcid-gaau01-gui-auth jobphase:Running

URL=$(kubectl get cm -n litmus config -o=jsonpath="{.items}{.data.url}")
echo -e "\nDOP URL: $URL\n"
cd gui-automation

######################
##   Running test  ##
######################

python3.7 -m pip install -r requirements.txt

#Running tests with gaau01 marker
python3.7 -m pytest -m gaau01 --url $URL --environment remote -v --tests-per-worker 10 --reruns 1 --html=./results/report.html

cd ..

bash utils/e2e-cr jobname:tcid-gaau01-gui-auth jobphase:Completed
}

if [ "$1" == "node" ];then
  node
else
  pod
fi
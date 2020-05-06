#!/bin/bash

pod() {

## Running gui-dasboard-topology test
echo -e "\n************************ Running GUI dasboard-topology test ***************************\n"
sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/director-gui/tcid-gato01-gui-dashboard-topology.sh node'
}

node() {

bash utils/pooling jobname:selenium-grid-deploy
bash utils/e2e-cr jobname:tcid-gato01-gui-dashboard-topology jobphase:Running

URL=$(kubectl get cm -n litmus config -o=jsonpath="{.items}{.data.url}")
echo -e "\nDOP URL: $URL\n"
cd gui-automation

######################
##   Running test  ##
######################

python3.7 -m pip install -r requirements.txt

#Running tests with gato01 marker
python3.7 -m pytest -m gato01 --url $URL --environment remote -v --tests-per-worker 10 --reruns 1 --html=./results/report.html

cd ..

bash utils/e2e-cr jobname:tcid-gato01-gui-dashboard-topology jobphase:Completed
}

if [ "$1" == "node" ];then
  node
else
  pod
fi
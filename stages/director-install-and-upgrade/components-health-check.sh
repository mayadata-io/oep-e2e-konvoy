#!/bin/bash

pod() {
  echo "*************Deploying Director On-Prem*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/director-install-and-upgrade/dop-deploy.sh node'
}

node() {
# Sequencing Jobs
bash utils/pooling jobname:dop-deploy
bash utils/e2e-cr jobname:components-health-check jobphase:Running

## Run Prerequisites
echo -e "\n********* [ Making logs directory ] **********\n";
mkdir -pv logs/basic-sanity-tests

## Run OEP basic sanity checks
echo -e "\n Starting OEP Basic Sanity Checks ************************************************************\n";
echo -e "------------------------------------------\n" >> result.txt

# Run maya-io-server check
echo -e "\n********** [ Running maya-io-server check ] **********\n";
chmod 755 ./stages/director-install-and-upgrade/basic-sanity-tests/maya-io-server-check.sh
./stages/director-install-and-upgrade/basic-sanity-tests/maya-io-server-check.sh > ./logs/basic-sanity-tests/maya-io-server-check.log &

# Run maya-ui check
echo -e "\n************* [ Running maya-ui check ] **************\n";
chmod 755 ./stages/director-install-and-upgrade/basic-sanity-tests/maya-ui-check.sh
./stages/director-install-and-upgrade/basic-sanity-tests/maya-ui-check.sh > ./logs/basic-sanity-tests/maya-ui-check.log &

# # Run od-elasticsearch check
# echo -e "\n********* [ Running od-elasticsearch check ] *********\n";
# chmod 755 ./basic-sanity-tests/od-elasticsearch-check.sh
# ./basic-sanity-tests/od-elasticsearch-check.sh > ./logs/basic-sanity-tests/od-elasticsearch-check.log &

# # Run od-kibana check
# echo -e "\n************ [ Running od-kibana check ] *************\n";
# chmod 755 ./basic-sanity-tests/od-kibana-check.sh
# ./basic-sanity-tests/od-kibana-check.sh > ./logs/basic-sanity-tests/od-kibana-check.log &

# # Run alertmanager check
# echo -e "\n*********** [ Running alertmanager check ] ***********\n";
# chmod 755 ./basic-sanity-tests/alertmanager-check.sh
# ./basic-sanity-tests/alertmanager-check.sh > ./logs/basic-sanity-tests/alertmanager-check.log &

# # Run alertstore check
# echo -e "\n************ [ Running alertstore check ] ************\n";
# chmod 755 ./basic-sanity-tests/alertstore-check.sh
# ./basic-sanity-tests/alertstore-check.sh > ./logs/basic-sanity-tests/alertstore-check.log &

# # Run alertstore-tablemanager check
# echo -e "\n****** [ Running alertstore-tablemanager check ] *****\n";
# chmod 755 ./basic-sanity-tests/alertstore-tablemanager-check.sh
# ./basic-sanity-tests/alertstore-tablemanager-check.sh > ./logs/basic-sanity-tests/alertstore-tablemanager-check.log &

# # Run cassandra check
# echo -e "\n************ [ Running cassandra check ] *************\n";
# chmod 755 ./basic-sanity-tests/cassandra-check.sh
# ./basic-sanity-tests/cassandra-check.sh > ./logs/basic-sanity-tests/cassandra-check.log &

# # Run chat-server check
# echo -e "\n*********** [ Running chat-server check ] ************\n";
# chmod 755 ./basic-sanity-tests/chat-server-check.sh
# ./basic-sanity-tests/chat-server-check.sh > ./logs/basic-sanity-tests/chat-server-check.log &

# # Run cloud-agent check
# echo -e "\n*********** [ Running cloud-agent check ] ************\n";
# chmod 755 ./basic-sanity-tests/cloud-agent-check.sh
# ./basic-sanity-tests/cloud-agent-check.sh > ./logs/basic-sanity-tests/cloud-agent-check.log &

# # Run configs check
# echo -e "\n************* [ Running configs check ] **************\n";
# chmod 755 ./basic-sanity-tests/configs-check.sh
# ./basic-sanity-tests/configs-check.sh > ./logs/basic-sanity-tests/configs-check.log &

# # Run configs-db check
# echo -e "\n************ [ Running configs-db check ] ************\n";
# chmod 755 ./basic-sanity-tests/configs-db-check.sh
# ./basic-sanity-tests/configs-db-check.sh > ./logs/basic-sanity-tests/configs-db-check.log &

# # Run consul check
# echo -e "\n************** [ Running consul check ] **************\n";
# chmod 755 ./basic-sanity-tests/consul-check.sh
# ./basic-sanity-tests/consul-check.sh > ./logs/basic-sanity-tests/consul-check.log &

# # Run distributor check
# echo -e "\n************ [ Running distributor check ] ***********\n";
# chmod 755 ./basic-sanity-tests/distributor-check.sh
# ./basic-sanity-tests/distributor-check.sh > ./logs/basic-sanity-tests/distributor-check.log &

# # Run ingester check
# echo -e "\n************* [ Running ingester check ] *************\n";
# chmod 755 ./basic-sanity-tests/ingester-check.sh
# ./basic-sanity-tests/ingester-check.sh > ./logs/basic-sanity-tests/ingester-check.log &

# # Run ingress-nginx check
# echo -e "\n********** [ Running ingress-nginx check ] ***********\n";
# chmod 755 ./basic-sanity-tests/ingress-nginx-check.sh
# ./basic-sanity-tests/ingress-nginx-check.sh > ./logs/basic-sanity-tests/ingress-nginx-check.log &

# # Run maya-grafana check
# echo -e "\n********** [ Running maya-grafana check ] ************\n";
# chmod 755 ./basic-sanity-tests/maya-grafana-check.sh
# ./basic-sanity-tests/maya-grafana-check.sh > ./logs/basic-sanity-tests/maya-grafana-check.log &

# # Run memcached check
# echo -e "\n************ [ Running memcached check ] *************\n";
# chmod 755 ./basic-sanity-tests/memcached-check.sh
# ./basic-sanity-tests/memcached-check.sh > ./logs/basic-sanity-tests/memcached-check.log &

# # Run mysql check
# echo -e "\n************** [ Running mysql check ] ***************\n";
# chmod 755 ./basic-sanity-tests/mysql-check.sh
# ./basic-sanity-tests/mysql-check.sh > ./logs/basic-sanity-tests/mysql-check.log &

# # Run querier check
# echo -e "\n************* [ Running querier check ] **************\n";
# chmod 755 ./basic-sanity-tests/querier-check.sh
# ./basic-sanity-tests/querier-check.sh > ./logs/basic-sanity-tests/querier-check.log &

# # Run ruler check
# echo -e "\n************** [ Running ruler check ] ***************\n";
# chmod 755 ./basic-sanity-tests/ruler-check.sh
# ./basic-sanity-tests/ruler-check.sh > ./logs/basic-sanity-tests/ruler-check.log &

wait
echo -e "\n------------------------------------------" >> result.txt
## Show results
echo -e "\n Results ***********************************************************************************";
cat result.txt;
echo -e "\n********** Basics Sanity Checks finished **********!"

}

if [ "$1" == "node" ];then
  node
else
  pod
fi

#!/bin/bash

pod() {
  echo "*************Deploying Director On-Prem*************"
  sshpass -p $pass ssh -o StrictHostKeyChecking=no $user@$ip -p $port 'cd oep-e2e-konvoy && bash stages/director-install/dop-deploy.sh node '"'$GITHUB_USERNAME'"' '"'$GITHUB_PASSWORD'"' '"'$RELEASE_USERNAME'"' '"'$RELEASE_PASSWORD'"' '"'$RELEASE'"''
}

node() {
  #bash utils/e2e-cr jobname:dop-deploy jobphase:Waiting
  #bash utils/e2e-cr jobname:dop-deploy jobphase:Running 
  #bash utils/e2e-cr jobname:components-health-check jobphase:Waiting

  GITHUB_USERNAME=$1
  GITHUB_PASSWORD=$2
  RELEASE_USERNAME=$3
  RELEASE_PASSWORD=$4
  RELEASE=$5

  # Setting up DOP_URL variable

  DOP_URL=$(kubectl get nodes -o wide --no-headers | awk {'print $6'} | awk 'NR==2'):30380
  echo -e "\n DOP URL: $DOP_URL"

  #####################################
  ##           Deploy DOP            ##
  #####################################

  echo -e "\n[ Cloning director-charts-internal repo ]\n"

  git clone https://$GITHUB_USERNAME:$GITHUB_PASSWORD@github.com/mayadata-io/director-charts-internal.git

  cd director-charts-internal

  echo -e "\n[ Get DOP release version ]-------------------------------------\n"
  echo -e "Release Version: $RELEASE\n"

  # Get into latest release directory of helm chart
  cd "$RELEASE"/director

  # Create secret having maya-init repo access
  kubectl create secret docker-registry directoronprem-registry-secret --docker-server=registry.mayadata.io --docker-username=$RELEASE_USERNAME --docker-password=$RELEASE_PASSWORD

  # Create clusterrolebinding
  kubectl create clusterrolebinding kube-admin --clusterrole cluster-admin --serviceaccount=kube-system:default

  # Replace storageClass to be used to openebs-hostpath in values.yaml
  sed 's/storageClass: standard/storageClass: openebs-hostpath/' -i ./values.yaml
  cat values.yaml

  # Apply helm chart
  helm install --name dop . --set server.url=$DOP_URL --set nginx-ingress.controller.kind=Deployment --set nginx-ingress.controller.service.enabled=true

  # Dump Director On-Prem pods
  echo -e "\n[ Dumping Director On-Prem components ]\n"
  kubectl get pod

  # Go back to oep-e2e-konvoy directory
  cd ~/oep-e2e-konvoy/

  # Add manual sleep of 9min
  echo -e "\n Manual wait for director components to get deployed"
  sleep 540

  #Run Components health check
  chmod 755 ./stages/director-install/components-health-check.sh
  ./stages/director-install/components-health-check.sh

  #List pods
  kubectl get pods

  #bash utils/e2e-cr jobname:dop-deploy jobphase:Completed 
}

if [ "$1" == "node" ];then
  node $2 $3 $4 $5 $6
else
  pod
fi

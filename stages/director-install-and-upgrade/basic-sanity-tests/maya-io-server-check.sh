#!/bin/bash

# Run maya-io-server-check litmus job
kubectl create -f oep/litmus/director/maya-io-server/run_litmus_test.yml

# Specify test name
test_name=maya-io-server-check
echo "Test name: $test_name"

# Get maya-io-server-check job's pod name
litmus_pod=$(kubectl get po -n litmus | grep $test_name  | awk {'print $1'} | tail -n 1)
echo "Litmus pod name: $litmus_pod"

job_status=$(kubectl get po $litmus_pod -n litmus | awk {'print $3'} | tail -n 1)

# Check completed status for job
while [[ "$job_status" != "Completed" ]]
do 
  job_status=$(kubectl get po  $litmus_pod -n litmus | awk {'print $3'} | tail -n 1)
  echo "Waiting for job status to be Completed"
  sleep 6
done

# Print maya-io-server-check job logs
echo "\n\nJob logs:"
kubectl logs -f $litmus_pod -n litmus

# Check maya-io-server-check job results
testResult=$(kubectl get litmusresult ${test_name} --no-headers -o custom-columns=:spec.testStatus.result)
# Print test result
echo -e "\n\n"
echo "%%%%%%%%%%%%%%%%%%%%%%%"
echo "%% Test result: $testResult %%"
echo "%%%%%%%%%%%%%%%%%%%%%%%"

# Flush test result in result.txt
echo "$test_name: $testResult" >> result.txt;
#!/bin/bash -e

region=${1-"us-east-1"}
environment=${2-"dr"}

get_stacks () {
  aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --region $region \
    --query 'StackSummaries[].StackName' --output text
}

get_stack_env () {
  stack=$1;
  shift;

  aws cloudformation describe-stacks --stack-name $stack --region $region --query 'Stacks[0].Tags[?Key==`Environment`].Value' --output text
}

for i in $(get_stacks) ; do
  if [ "$(get_stack_env $i)" == "$environment" ]; then
    aws cloudformation delete-stack --stack-name $i --region $region
  fi
done

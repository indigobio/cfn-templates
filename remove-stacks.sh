#!/bin/bash -e

region=${1-"us-east-1"}
environment=${2-"dr"}

get_stacks () {
  aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region $region | \
    jq '.StackSummaries[].StackName' | \
    tr -d '"'
}

get_stack_env () {
  stack=$1;
  shift;

  local res=$(aws cloudformation describe-stacks --stack-name $stack --region $region | \
    jq "if .Stacks[0].Tags[] | select(.Key == \"Environment\").Value == \"$environment\" then .Stacks[0].StackName else \"no\" end" | \
    tr -d '"')
  [[ $res == $stack ]] && return 0
  return 1
}

for i in $(get_stacks) ; do
  if get_stack_env $i; then
    aws cloudformation delete-stack --stack-name $i
  fi
done

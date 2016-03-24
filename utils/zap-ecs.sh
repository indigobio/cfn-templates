#!/bin/bash

environment=$1

for cluster in $(aws ecs list-clusters --query 'clusterArns[]' --output table | grep indigo-$environment-empire | awk '{print $2}'); do
  for service in $(aws ecs list-services --cluster $cluster --query 'serviceArns[]' --output text); do
    aws ecs update-service --cluster $cluster --service $service --desired-count 0
    aws ecs delete-service --cluster $cluster --service $service
  done
  aws ecs delete-cluster --cluster $cluster
done

# TODO: zap orphaned load balanacers.

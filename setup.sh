#!/bin/bash
cfn-create-stack $1 --disable-rollback \
  --parameters "ChefEnvironment=dr;ChefServerPrivateKeyBucket=gswallow-indigo;ChefServerURL=https://api.opscode.com/organizations/product_dev;ChefValidationClientUsername=product_dev-validator;InstanceType=m3.medium;KeyName=indigo-biosystems;SSHLocation=0.0.0.0/0;StackLabel="$1";VolumeSize=10" \
  --template-url https://s3.amazonaws.com/gswallow-cfn-templates-us-east-1/mongo-replicaset-stack.template \
  --capabilities CAPABILITY_IAM \
  --show-long

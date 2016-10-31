#!/usr/bin/env bash

echo "Searching buckets"
for bucket in $(aws s3api list-buckets --query 'Buckets[?contains(Name, '\`$environment\`')].Name' --output text); do
  if [ ! -z "$(aws s3api get-bucket-tagging --bucket $bucket --query 'TagSet[?Key == `Purpose`]|[?Value == `lambda`]' --output text 2> null)" ]; then
    echo "Copying functions to $bucket"
    cd functions
    for function in *; do
      echo "Building deployment package for $function"
      cd $function && ./create_deployment_package.sh && cd ..
      echo "Syncing $function"
      aws s3 sync $function/ s3://$bucket/$function --exclude '*' --include '*.zip'
    done
  fi
done

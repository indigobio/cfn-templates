#!/usr/bin/env bash

chef_key=${chef_key:=~/.chef/lambda.pem}
mkdir /tmp/deregister_chef_node
virtualenv /tmp/pychef
source /tmp/pychef/bin/activate
pip install pychef
cp -r /tmp/pychef/lib/python2.7/site-packages/*[Cc]hef* /tmp/deregister_chef_node
cp -r .chef /tmp/deregister_chef_node
cp $chef_key /tmp/deregister_chef_node/.chef/lambda.pem
chmod 600 /tmp/deregister_chef_node/.chef/lambda.pem
cp deregister_chef_node.py /tmp/deregister_chef_node
pushd /tmp/deregister_chef_node
zip -r ../deregister_chef_node.zip * .chef
popd
cp /tmp/deregister_chef_node.zip .
rm -rf /tmp/deregister_chef_node /tmp/deregister_chef_node.zip /tmp/pychef

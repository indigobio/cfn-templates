#!/usr/bin/env bash

mkdir /tmp/deregister_chef_node
virtualenv /tmp/pychef
source /tmp/pychef/bin/activate
pip install pychef
cp -r /tmp/pychef/lib/python2.7/site-packages/*[Cc]hef* /tmp/deregister_chef_node
cp deregister_chef_node.py /tmp/deregister_chef_node
pushd /tmp/deregister_chef_node
zip -r ../deregister_chef_node.zip *
popd
cp /tmp/deregister_chef_node.zip .
rm -rf /tmp/deregister_chef_node /tmp/deregister_chef_node.zip /tmp/pychef

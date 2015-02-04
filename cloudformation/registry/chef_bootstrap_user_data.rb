SparkleFormation::Registry.register(:chef_bootstrap) do

  user_data base64!(
    join!(
      "#!/bin/bash\n",
      "## Error reporting helper function\n",
      "  function error_exit\n",
      "  {\n",
      "    /usr/local/bin/cfn-signal -e 1 -r \"$1\" '", ref!(WaitHandleOpenVPNDevice" }, "'\n",
      "    exit 1\n",
      "  }\n\n",

      "# cfn-init complains that the wheel group doesn't exist\n",
      "groupadd wheel\n",
      "usermod -a -G wheel root\n\n",

      "gpg --keyserver pgpkeys.mit.edu --recv-key 40976EAF437D05B5\n",
      "gpg -a --export 40976EAF437D05B5 | apt-key add -\n",
      "apt-get update\n",
      "apt-get -y install python-setuptools s3cmd\n",
      "# srsly wtf?\n",
      "apt-get -y --force-yes install ca-certificates=20111211\n",
      "mkdir -p /etc/chef/ohai/hints\n",
      "touch /etc/chef/ohai/hints/ec2.json\n",
      "easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz\n\n",

      "/usr/local/bin/cfn-init -s ", { "Ref" : "AWS::StackName" }, " -r OpenVPNDevice ",
      " --access-key ", { "Ref" : "HostKeys" },
      " --secret-key ", {"Fn::GetAtt": ["HostKeys", "SecretAccessKey"]},
      " --region ", { "Ref" : "AWS::Region" }, " || error_exit 'Failed to initialize chef-solo through LaunchConfig'\n\n",

      "# Bootstrap Chef\n",
      "chef-solo -c /etc/chef/solo.rb -j /etc/chef/chef.json -r http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz >> /tmp/cfn-init.log 2>&1  || error_exit Failed to run chef-solo: $(</tmp/cfn-init.log)\n\n",

      "# Fix up the server URL in client.rb\n",
      "s3cmd -c /home/ubuntu/.s3cfg get s3://", { "Ref": "ChefServerPrivateKeyBucket" }, "/validation.pem /etc/chef/validation.pem >> /tmp/cfn-init.log 2>&1 || error_exit Failed to get Chef validation key: $(</tmp/cfn-init.log)\n\n",
      "s3cmd -c /home/ubuntu/.s3cfg get s3://", { "Ref": "ChefServerPrivateKeyBucket" }, "/encrypted_data_bag_secret /etc/chef/encrypted_data_bag_secret >> /tmp/cfn-init.log 2>&1 || error_exit Failed to get data bag secret: $(</tmp/cfn-init.log)\n\n",
      "chmod 0600 /etc/chef/encrypted_data_bag_secret\n",
      "sed -i 's|http://localhost:4000|", { "Ref": "ChefServerURL" }, "|g' /etc/chef/client.rb\n\n",

      "# Run chef-client\n",
      "chef-client -E ", { "Ref" : "ChefEnvironment" }, " -j /etc/chef/roles.json >> /tmp/cfn-init.log 2>&1 || error_exit Failed to initialize host via chef-client: $(</tmp/cfn-init.log)\n\n",

      "# We out.\n",
      "status=$?\n",
      "/usr/local/bin/cfn-signal -e $status '", { "Ref" : "WaitHandleOpenVPNDevice" }, "'\n",
      "echo /usr/local/bin/cfn-signal -e $status '", { "Ref" : "WaitHandleOpenVPNDevice" }, "' >> /tmp/cfn-init.log 2>&1\n"
    )
  )

end
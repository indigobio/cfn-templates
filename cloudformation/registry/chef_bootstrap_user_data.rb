SparkleFormation::Registry.register(:chef_bootstrap_user_data) do

  user_data base64!(
    join!(
      "#!/bin/bash\n",

      # This won't work
      "source /tmp/.cfn-functions.sh\n\n",

      "# cfn-init complains that the wheel group doesn't exist\n",
      "groupadd wheel\n",
      "usermod -a -G wheel root\n\n",

      "gpg --keyserver pgpkeys.mit.edu --recv-key 40976EAF437D05B5\n",
      "gpg -a --export 40976EAF437D05B5 | apt-key add -\n",
      "apt-get update\n",
      "apt-get -y install python-setuptools s3cmd\n",
      "# srsly why?\n",
      "apt-get -y --force-yes install ca-certificates=20111211\n",
      "mkdir -p /etc/chef/ohai/hints\n",
      "touch /etc/chef/ohai/hints/ec2.json\n",
      "easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz\n\n",

      # because this needs to run first.
      "cfn_init\n\n",

      # so add this (but right now I can't figure out how to set the resource name.)
      "/usr/local/bin/cfn-init -s ", ref!("AWS::StackName"), " -r ", _config[:resource_name_in_cfn_signal] || _name.to_sym,
      "   --access-key ", ref!(:cfn_keys),
      "   --secret-key ", attr!(:cfn_keys, :secret_access_key),
      "   --region ", ref!("AWS::Region"), " || cfn_signal_failure_and_exit 'Failed to initialize LaunchConfig'\n",

      "# Bootstrap Chef\n",
      "chef-solo -c /etc/chef/solo.rb -j /etc/chef/chef-client-config.json -r http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz >> /tmp/cfn-init.log 2>&1  || cfn_signal_failure_exit Failed to run chef-solo: $(</tmp/cfn-init.log)\n\n",

      "# Fix up the server URL in client.rb\n",
      "s3cmd -c /home/ubuntu/.s3cfg get s3://", ref!(:chef_validator_key_bucket), "/validation.pem /etc/chef/validation.pem >> /tmp/cfn-init.log 2>&1 || cfn_signal_failure_and_exit Failed to get Chef validation key: $(</tmp/cfn-init.log)\n\n",
      "s3cmd -c /home/ubuntu/.s3cfg get s3://", ref!(:chef_validator_key_bucket), "/encrypted_data_bag_secret /etc/chef/encrypted_data_bag_secret >> /tmp/cfn-init.log 2>&1 || cfn_signal_failure_and_exit Failed to get data bag secret: $(</tmp/cfn-init.log)\n\n",
      "chmod 0600 /etc/chef/encrypted_data_bag_secret\n",
      "#sed -i 's|http://localhost:4000|", ref!(:chef_server_u_r_l), "|g' /etc/chef/client.rb\n\n",

      "# Run chef-client\n",
      "chef-client -E ", ref!(:chef_environment), " -j /etc/chef/chef-client-bootstrap.json >> /tmp/cfn-init.log 2>&1 || cfn_signal_failure_and_exit Failed to initialize host via chef-client: $(</tmp/cfn-init.log)\n\n",

      "cfn_signal_success_and_exit\n"
    )
  )
end
SparkleFormation.dynamic(:bootstrap_instance) do |_name, _config|

  parameters(:chef_run_list) do
    type 'CommaDelimitedList'
    default 'role[base]'
  end

  parameters(:chef_validation_client_user_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default 'product_dev-validator'
    description 'Validator Client Name'
  end

  parameters(:chef_environment) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default '_default'
    description 'Chef Environment Name'
  end

  parameters('ChefServerURL') do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default 'https://api.opscode.com/organizations/product_dev'
  end

  resources("#{_name}_bootstrap_instance".to_sym) do
    type 'AWS::EC2::Instance'
    registry!(:chef_bootstrap_files, "#{_name}_bootstrap_instance".to_sym)
    properties do
      image_id map!(:ami_to_region, 'AWS::Region', :ami)
      instance_type _config[:instance_type]
      key_name _config[:ssh_key_name]
      source_dest_check _config[:source_dest_check] || 'true' # I originally used this template for a NAT instance.
      # TODO: decouple the security group ids from the instance.
      security_group_ids [ ref!("#{_name}_instance_security_group".to_sym) ]
      user_data base64!(
        join!(
          "#!/bin/bash\n\n",

          "# We are using resource signaling, rather than wait condition handles\n",
          "# http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-signal.html\n",
          "function cfn_signal_and_exit\n",
          "{\n",
          "  status=$?\n",
          "  /usr/local/bin/cfn-signal --access-key ", ref!(:cfn_keys),
          "   --secret-key ", attr!(:cfn_keys, :secret_access_key),
          "   --region ", ref!("AWS::Region"),
          "   --resource ", _config[:resource_name_in_cfn_signal] || "#{_name}_bootstrap_instance".to_sym,
          "   --stack ", ref!('AWS::StackName'),
          "   --exit-code $status\n",
          "  exit $status\n",
          "}\n\n",

          "apt-get update\n",
          "apt-get -y install python-setuptools s3cmd\n",
          "mkdir -p /etc/chef/ohai/hints\n",
          "touch /etc/chef/ohai/hints/ec2.json\n",
          "easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz\n\n",

          "/usr/local/bin/cfn-init -s ", ref!("AWS::StackName"), " --resource ", _config[:resource_name_in_cfn_signal] || "IndigoBootstrapInstance",
          "   --access-key ", ref!(:cfn_keys),
          "   --secret-key ", attr!(:cfn_keys, :secret_access_key),
          "   --region ", ref!("AWS::Region"), " || cfn_signal_and_exit\n\n",

          "# Bootstrap Chef\n",
          "curl -sL https://www.chef.io/chef/install.sh | sudo bash >> /tmp/cfn-init.log 2>&1 || cfn_signal_and_exit\n",
          "s3cmd -c /home/ubuntu/.s3cfg get s3://", ref!(:chef_validator_key_bucket), "/validation.pem /etc/chef/validation.pem >> /tmp/cfn-init.log 2>&1 || cfn_signal_and_exit\n",
          "s3cmd -c /home/ubuntu/.s3cfg get s3://", ref!(:chef_validator_key_bucket), "/encrypted_data_bag_secret /etc/chef/encrypted_data_bag_secret >> /tmp/cfn-init.log 2>&1 || cfn_signal_and_exit\n",
          "chmod 0600 /etc/chef/encrypted_data_bag_secret\n",
          "chef-client -E ", ref!(:chef_environment), " -j /etc/chef/first-run.json >> /tmp/cfn-init.log 2>&1 || cfn_signal_and_exit\n\n",

          "cfn_signal_and_exit\n"
        )
      )
      tags _array(
        -> {
          key 'Name'
          value join!('indigo', ref!('AWS::Region'),  _name, {:options => { :delimiter => '-' }})
        }
      )
    end
  end

  # TODO: The following resources should probably be declared in the high-level template, or at least elsewhere than here.
  resources("#{_name}_instance_security_group".to_sym) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description "#{_name} instance security group"
    end
  end

  resources("#{_name}_instance_security_group_ingress".to_sym) do
    type 'AWS::EC2::SecurityGroupIngress'
    properties do
      group_id attr!("#{_name}_instance_security_group".to_sym, :group_id)
      cidr_ip '0.0.0.0/0'
      ip_protocol 'tcp'
      from_port '22'
      to_port '22'
    end
  end

  # TODO: outputs
end


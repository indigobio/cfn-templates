SparkleFormation.dynamic(:bootstrapped_instance) do |_name, _config|
  # _config[:security_group] must be set to a security group.
  # _config[:no_subnet] will generate a template to create an ec2 classic instance.

  parameters(:chef_run_list) do
    type 'CommaDelimitedList'
    default _config[:chef_run_list] || 'role[base]'
  end

  parameters(:chef_validation_client_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default _config[:chef_validation_client_name] || 'product_dev-validator'
    description 'Validator Client Name'
  end

  parameters(:chef_environment) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default _config[:chef_environment] || '_default'
    description 'Chef Environment Name'
  end

  parameters('ChefServerURL') do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default _config[:chef_server_url] || 'https://api.opscode.com/organizations/product_dev'
  end

  parameters("#{_name}_instance_ebs_optimized".to_sym) do
    type 'String'
    allowed_values _array('true', 'false')
    default _config[:ebs_optimized] || 'false'
    description 'Create an EBS-optimized instance (additional charges apply)'
  end

  if _config.fetch(:no_subnet, false)
    parameters("#{_name}_instance_az".to_sym) do
      type 'String'
      registry!(:az_values)
      default _config[:az] || registry!(:default_az)
      description 'Availability zone to contain instance'
    end
  else
    parameters("#{_name}_instance_subnet".to_sym) do
      type 'AWS::EC2::Subnet::Id'
      description "Subnet to hold the #{_name} instance"
    end
  end

  parameters("#{_name}_instance_source_dest_check".to_sym) do
    type 'String'
    allowed_values _array('true', 'false')
    default _config[:source_dest_check] || 'true'
    description 'Check source/destination addresses of packets from this instance'
  end

  resources("#{_name}_instance".to_sym) do
    type 'AWS::EC2::Instance'
    registry!(:chef_bootstrap_files)
    properties do
      image_id map!(:region_to_ami, 'AWS::Region', :ami)
      instance_type ref!(_config[:instance_type])
      key_name ref!(_config[:ssh_key_pair])
      source_dest_check _config[:source_dest_check] || 'true'
      security_group_ids _config[:security_groups].collect { |sg| attr!(sg, :group_id) }
      if _config.fetch(:no_subnet, false)
        availability_zone ref!("#{_name}_instance_az".to_sym)
      else
        subnet_id ref!("#{_name}_instance_subnet".to_sym)
      end
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
          "   --resource ", "#{_name.capitalize}Instance",
          "   --stack ", ref!('AWS::StackName'),
          "   --exit-code $status\n",
          "  exit $status\n",
          "}\n\n",

          "apt-get update\n",
          "apt-get -y install python-setuptools s3cmd\n",
          "mkdir -p /etc/chef/ohai/hints\n",
          "touch /etc/chef/ohai/hints/ec2.json\n",
          "easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz\n\n",

          "/usr/local/bin/cfn-init -s ", ref!("AWS::StackName"), " --resource ", "#{_name.capitalize}Instance",
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

  outputs ("#{_name}_instance_ip_address".to_sym) do
    description "The IP address of the #{_name} instance"
    #value attr!(ref!("#{_name}_instance".to_sym), :public_ip)
    value attr!("#{_name}_instance".to_sym, :public_ip)
  end
end


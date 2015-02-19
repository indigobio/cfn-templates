SparkleFormation.dynamic(:launch_config) do |_name, _config = {}|
  # either _config[:volume_count] or _config[:snapshots] must be set
  # to generate a template with EBS device mappings.

=begin
TODO (maybe): When you use an instance to create a launch configuration, all
properties are derived from the instance with the exception of
BlockDeviceMapping and AssociatePublicIpAddress. You can override any
properties from the instance by specifying them in the launch configuration.
=end

  conditions.set!(
    "#{_name}_volumes_are_io1".to_sym,
    equals!(ref!("#{_name}_ebs_volume_type".to_sym), 'io1')
  )

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

  parameters("#{_name}_security_groups".to_sym) do
    type 'List<AWS::EC2::SecurityGroup::Id>'
  end

  parameters("#{_name}_ebs_volume_size".to_sym) do
    type 'Number'
    min_value '1'
    max_value '1000'
    default _config[:volume_size] || '100'
  end

  parameters("#{_name}_ebs_volume_type".to_sym) do
    type 'String'
    allowed_values _array('standard', 'gp2', 'io1')
    default _config[:volume_type] || 'gp2'
    description 'Magnetic (standard), General Purpose (gp2), or Provisioned IOPS (io1)'
  end

  parameters("#{_name}_ebs_provisioned_iops".to_sym) do
    type 'Number'
    min_value '1'
    max_value '4000'
    default _config[:piops] || '300'
  end

  parameters("#{_name}_delete_ebs_volume_on_termination".to_sym) do
    type 'String'
    allowed_values ['true', 'false']
    default _config[:del_on_term] || 'true'
  end

  parameters("#{_name}_instances_ebs_optimized".to_sym) do
    type 'String'
    allowed_values _array('true', 'false')
    default _config[:ebs_optimized] || 'false'
    description 'Create an EBS-optimized instance (additional charges apply)'
  end

  resources("#{_name}_launch_config".to_sym) do
    type 'AWS::AutoScaling::LaunchConfiguration'
    registry!(:chef_bootstrap_files) # metadata
    properties do
      instance_type ref!(:instance_type)
      image_id map!(:region_to_ami, 'AWS::Region', :ami)
      key_name ref!(:ssh_key_pair)
      if _config.has_key?(:security_groups)
        security_groups _config[:security_groups].collect { |sg| attr!(sg, :group_id) }
      else
        security_groups ref!("#{_name}_security_groups".to_sym)
      end
      ebs_optimized ref!("#{_name}_instances_ebs_optimized".to_sym)
      count = 0
      if _config.has_key?(:snapshots)
        count = _config[:snapshots].count
      elsif _config.has_key?(:volume_count)
        count = _config[:volume_count].to_i
      end
      block_device_mappings array!(
        *count.times.map { |d| -> {
          device_name  "/dev/sd#{(102 + d).chr}"
          ebs do
            iops if!("#{_name}_volumes_are_io1".to_sym, ref!("#{_name}_ebs_provisioned_iops".to_sym), no_value!)
            delete_on_termination ref!("#{_name}_delete_ebs_volume_on_termination".to_sym)
            if _config.has_key?(:snapshots)
              if _config[:snapshots][d]
                snapshot_id _config[:snapshots][d]
              end
            end
            volume_type ref!("#{_name}_ebs_volume_type".to_sym)
            volume_size ref!("#{_name}_ebs_volume_size".to_sym)
          end
          }
        }
      )
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
          "   --resource ", "#{_name.capitalize}Asg",
          "   --stack ", ref!('AWS::StackName'),
          "   --exit-code $status\n",
          "  exit $status\n",
          "}\n\n",

          "apt-get update\n",
          "apt-get -y install python-setuptools s3cmd\n",
          "mkdir -p /etc/chef/ohai/hints\n",
          "touch /etc/chef/ohai/hints/ec2.json\n",
          "easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz\n\n",

          "/usr/local/bin/cfn-init -s ", ref!("AWS::StackName"), " --resource ", "#{_name.capitalize}LaunchConfig",
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
    end
  end
end
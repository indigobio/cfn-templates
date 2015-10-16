SparkleFormation.dynamic(:launch_config_windows_bootstrap) do |_name, _config = {}|

  # either _config[:volume_count] or _config[:snapshots] must be set
  # to generate a template with EBS device mappings.

  # {
  #   "Type" : "AWS::AutoScaling::LaunchConfiguration",
  #   "Properties" : {
  #     "AssociatePublicIpAddress" : Boolean,
  #     "BlockDeviceMappings" : [ BlockDeviceMapping, ... ],
  #     "EbsOptimized" : Boolean,
  #     "IamInstanceProfile" : String,
  #     "ImageId" : String,
  #     "InstanceId" : String,
  #     "InstanceMonitoring" : Boolean,
  #     "InstanceType" : String,
  #     "KernelId" : String,
  #     "KeyName" : String,
  #     "RamDiskId" : String,
  #     "SecurityGroups" : [ SecurityGroup, ... ],
  #     "SpotPrice" : String,
  #     "UserData" : String
  #   }
  # }

  _config[:ami_map] ||= :region_to_win2k8_ami
  _config[:iam_instance_profile] ||= :default_iam_instance_profile
  _config[:iam_instance_role] ||= :default_iam_instance_role
  _config[:chef_run_list] ||= 'role[windows_base]'

  parameters("#{_name}_instance_type".to_sym) do
    type 'String'
    allowed_values %w(t2.micro  t2.small   t2.medium
                      m3.medium m3.large   m3.xlarge  m3.2xlarge
                      m4.large  m4.xlarge  m4.2xlarge m4.4xlarge m4.10xlarge
                      c3.large  c3.xlarge  c3.2xlarge c3.4xlarge c3.8xlarge
                      c4.large  c4.xlarge  c4.2xlarge c4.4xlarge c4.8xlarge
                      r3.large  r3.xlarge  r3.2xlarge r3.4xlarge r3.8xlarge
                      i2.xlarge i2.2xlarge i2.4xlarge i2.8xlarge
                      )
    default _config[:instance_type] || 'm3.medium'
  end

  parameters("#{_name}_associate_public_ip_address".to_sym)do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:public_ips, 'false')
    description 'Associate public IP addresses to instances'
  end

  parameters(:chef_run_list) do
    type 'CommaDelimitedList'
    default _config[:chef_run_list]
    description 'The run list to run when Chef client is invoked'
  end

  parameters(:chef_validation_client_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _config[:chef_validation_client_name] || 'product_dev-validator'
    description 'Chef validation client name; see https://docs.chef.io/chef_private_keys.html'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:chef_environment) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _config[:chef_environment] || ENV['environment']
    description 'The Chef environment in which to bootstrap the instance'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:chef_server_url) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default _config[:chef_server_url] || 'https://api.opscode.com/organizations/product_dev'
  end

  if _config.fetch(:create_ebs_volumes, false)
    conditions.set!(
        "#{_name}_volumes_are_io1".to_sym,
        equals!(ref!("#{_name}_ebs_volume_type".to_sym), 'io1')
    )

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
  end

  resources("#{_name}_launch_config".to_sym) do
    type 'AWS::AutoScaling::LaunchConfiguration'
    registry!(:windows_bootstrap_files) # metadata
    properties do
      image_id map!(_config[:ami_map], ref!('AWS::Region'), :ami)
      instance_type ref!("#{_name}_instance_type".to_sym)
      iam_instance_profile ref!(_config[:iam_instance_profile])
      associate_public_ip_address ref!("#{_name}_associate_public_ip_address".to_sym)
      key_name ref!(:ssh_key_pair)

      security_groups _config[:security_groups]
      if _config.fetch(:create_ebs_volumes, false)
        ebs_optimized ref!("#{_name}_instances_ebs_optimized".to_sym)

        count = _config.fetch(:volume_count, 0)
        count = _config[:snapshots].count if _config.has_key?(:snapshots)

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
      end

      user_data base64!(
        join!(
          "<script>\n",

          %Q!powershell.exe -ExecutionPolicy Unrestricted -NoProfile -NonInteractive "invoke-restmethod -uri http://169.254.169.254/latest/meta-data/instance-id/ | new-item instance-id.txt -itemtype file"\n!,
          %Q!for /f "delims=" %%x in (instance-id.txt) do set INSTANCE_ID=%%x\n\n!,

          "cfn-init.exe -v -s ", ref!('AWS::StackName'), " --resource ", "#{_name.capitalize}LaunchConfig",
          " --region ", ref!('AWS::Region'), "\n\n",

          "if ERRORLEVEL 1 (\n",
          %Q!  "%PROGRAMFILES%\\Amazon\\AWSCLI\\AWS.exe" autoscaling set-instance-health --instance-id %INSTANCE_ID% --health-status Unhealthy --region !, ref!('AWS::Region'), "\n",
          ") else (\n",
          "  timeout /t 600\n",
          "  cfn-signal.exe",
          " --role ", ref!(_config[:iam_instance_role]),
          " --region ", ref!('AWS::Region'),
          " --resource ", "#{_name.capitalize}Asg",
          " --stack ", ref!('AWS::StackName'),
          " --exit-code %ERRORLEVEL%\n",
          ")\n",
          "</script>\n"
        )
      )
    end
  end
end

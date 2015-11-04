SparkleFormation.dynamic(:launch_config) do |_name, _config = {}|

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

  parameters(:nat_instance_type) do
    type 'String'
    allowed_values ['t2.micro', 't2.small', 't2.medium', 'm3.medium', 'm3.large', 'c4.large', 'c4.xlarge']
    default _config[:instance_type] || 't2.micro'
  end

  resources("#{_name}_launch_config".to_sym) do
    type 'AWS::AutoScaling::LaunchConfiguration'
    properties do
      image_id map!(:region_to_nat_ami, ref!('AWS::Region'), :ami)
      instance_type ref!(:nat_instance_type)
      associate_public_ip_address 'true'
      iam_instance_profile ref!(:nat_instance_iam_profile)
      key_name ref!(:ssh_key_pair)
      security_groups array!(
        *_config[:security_groups].map { |sg| ref!(sg) }
      )
      user_data registry!(:nat_user_data)
    end
  end
end

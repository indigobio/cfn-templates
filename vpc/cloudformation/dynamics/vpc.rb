SparkleFormation.dynamic(:vpc) do |_name|

  ENV['environment'] ||= 'dr'

  # {
  #   "Type" : "AWS::EC2::VPC",
  #   "Properties" : {
  #     "CidrBlock" : String,
  #     "EnableDnsSupport" : Boolean,
  #     "EnableDnsHostnames" : Boolean,
  #     "InstanceTenancy" : String,
  #     "Tags" : [ Resource Tag, ... ]
  #   }
  # }

  parameters(:enable_dns_support) do
    type 'String'
    allowed_values _array('true', 'false')
    default 'true'
    description 'Specifies whether DNS resolution is supported for the VPC'
  end

  parameters(:enable_dns_hostnames) do
    type 'String'
    allowed_values _array('true', 'false')
    default 'true'
    description 'Specifies whether the instances launched in the VPC get DNS hostnames'
  end

  parameters(:instance_tenancy) do
    type 'String'
    allowed_values ['default', 'dedicated']
    default 'default'
    description 'Dedicated: Any instance launched into the VPC will run on dedicated hardware (increased cost)'
  end

  parameters(:vpc_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _name
    description 'Specifies the name of the VPC being created'
    constraint_description 'can only contain ASCII characters'
  end

  resources(:vpc) do
    type 'AWS::EC2::VPC'
    properties do
      cidr_block map!(:cidr_to_region, 'AWS::Region', :cidr)
      enable_dns_support ref!(:enable_dns_hostnames)
      enable_dns_hostnames ref!(:enable_dns_hostnames)
      instance_tenancy ref!(:instance_tenancy)
      tags _array(
        -> {
          key 'Name'
          value ref!(:vpc_name)
        },
        -> {
          key 'Environment'
          value ENV['environment']
        }
      )
    end
  end
end
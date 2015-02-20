SparkleFormation.build do

  parameters(:vpc_enable_dns_support) do
    type 'String'
    allowed_values _array('true', 'false')
    default 'true'
  end

  parameters(:vpc_enable_dns_hostnames) do
    type 'String'
    allowed_values _array('true', 'false')
    default 'true'
  end

  parameters(:vpc_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default 'MyVPC'
  end

  resources(:vpc) do
    type 'AWS::EC2::VPC'
    properties do
      cidr_block map!(:cidr_to_region, 'AWS::Region', :cidr)
      tags _array(
        -> {
          key 'Name'
          value ref!(:vpc_name)
        }
      )
    end
  end
end
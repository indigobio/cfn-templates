SparkleFormation.build do
  parameters(:nat_instance_type) do
    type 'String'
    allowed_values ['m3.medium', 'm3.large', 'm3.xlarge']
    default 'm3.medium'
  end

  mappings.nat_ami_64 do
    set!('us-east-1', :ami => 'ami-184dc970') # amzn-ami-vpc-nat-hvm-2014.09.1.x86_64-gp2
    set!('us-west-1', :ami => 'ami-a98396ec')
    set!('us-west-2', :ami => 'ami-290f4119')
  end
end
SparkleFormation.build do
  mappings.region_to_nat_ami do
    set!('us-east-1'.disable_camel!,    :ami => 'ami-f5f41398') # amzn-ami-hvm-2015.09.2.x86_64-ebs (NOT the nat ami)
    set!('us-west-1'.disable_camel!,    :ami => 'ami-6e84fa0e')
    set!('us-west-2'.disable_camel!,    :ami => 'ami-d0f506b0')
  end
end

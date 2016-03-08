SparkleFormation.build do
  mappings.region_to_nat_ami do
    set!('us-east-1'.disable_camel!,    :ami => 'ami-8fcee4e5') # amzn-ami-hvm-2015.09.2.x86_64-ebs (NOT the nat ami)
    set!('us-west-1'.disable_camel!,    :ami => 'ami-d1f482b1')
    set!('us-west-2'.disable_camel!,    :ami => 'ami-63b25203')
  end
end
SparkleFormation.build do
  mappings.region_to_nat_ami do
    set!('us-east-1'.disable_camel!,    :ami => 'ami-1ecae776') # amzn-ami-hvm-2014.09.2.x86_64-ebs (NOT the nat ami)
    set!('us-west-1'.disable_camel!,    :ami => 'ami-d114f295')
    set!('us-west-2'.disable_camel!,    :ami => 'ami-e7527ed7')
  end
end
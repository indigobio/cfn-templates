SparkleFormation.build do
  mappings.region_to_nat_ami do
    set!('us-east-1'._no_hump, :ami => 'ami-184dc970') # amzn-ami-vpc-nat-hvm-2014.09.1.x86_64-gp2
    set!('us-west-1'._no_hump, :ami => 'ami-a98396ec')
    set!('us-west-2'._no_hump, :ami => 'ami-290f4119')
  end
end
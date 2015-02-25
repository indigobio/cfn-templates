SparkleFormation.build do
  mappings.region_to_nat_ami do
    set!('us-east-1'._no_hump,    :ami => 'ami-146e2a7c') # amzn-ami-hvm-2014.09.2.x86_64-ebs (NOT the nat ami)
    set!('us-west-1'._no_hump,    :ami => 'ami-42908907')
    set!('us-west-2'._no_hump,    :ami => 'ami-dfc39aef')
    set!('eu-west-1'._no_hump,    :ami => 'ami-9d23aeea')
    set!('eu-central-1'._no_hump, :ami => 'ami-04003319')
  end
end
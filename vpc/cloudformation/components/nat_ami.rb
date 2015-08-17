SparkleFormation.build do
  mappings.region_to_nat_ami do
    set!('us-east-1'._no_hump,    :ami => 'ami-1ecae776') # amzn-ami-hvm-2014.09.2.x86_64-ebs (NOT the nat ami)
    set!('us-west-1'._no_hump,    :ami => 'ami-d114f295')
    set!('us-west-2'._no_hump,    :ami => 'ami-e7527ed7')
    set!('eu-west-1'._no_hump,    :ami => 'ami-a10897d6')
    set!('eu-central-1'._no_hump, :ami => 'ami-a8221fb5')
  end
end
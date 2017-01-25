SparkleFormation.build do
  mappings.region_to_nat_ami do
    set!('us-east-1'.disable_camel!,    :ami => 'ami-0b33d91d') # amzn-ami-hvm-2015.09.2.x86_64-ebs (NOT the nat ami)
    set!('us-east-2'.disable_camel!,    :ami => 'ami-c55673a0')
    set!('us-west-1'.disable_camel!,    :ami => 'ami-165a0876')
    set!('us-west-2'.disable_camel!,    :ami => 'ami-f173cc91')
  end
end

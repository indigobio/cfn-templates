SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_empire_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-6d6b057b')
    set!('us-east-2'.disable_camel!, :ami => 'ami-cbe7c0ae')
    set!('us-west-1'.disable_camel!, :ami => 'ami-5d61473d')
    set!('us-west-2'.disable_camel!, :ami => 'ami-7db8231d')
  end
end

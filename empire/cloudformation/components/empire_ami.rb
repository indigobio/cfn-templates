SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_empire_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-cfd381a5')
    set!('us-west-1'.disable_camel!, :ami => 'ami-d9e983b9')
    set!('us-west-2'.disable_camel!, :ami => 'ami-5a8f963b')
  end
end
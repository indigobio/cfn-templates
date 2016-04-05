SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_empire_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-e8170082')
    set!('us-west-1'.disable_camel!, :ami => 'ami-45750925')
    set!('us-west-2'.disable_camel!, :ami => 'ami-0e67926e')
  end
end
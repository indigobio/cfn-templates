SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_empire_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-0615bc10')
    set!('us-east-2'.disable_camel!, :ami => 'ami-a25e7ac7')
    set!('us-west-1'.disable_camel!, :ami => 'ami-d3540cb3')
    set!('us-west-2'.disable_camel!, :ami => 'ami-efb33a8f')
  end
end

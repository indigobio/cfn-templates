SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_empire_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-03ee1c15')
    set!('us-east-2'.disable_camel!, :ami => 'ami-c82b0ead')
    set!('us-west-1'.disable_camel!, :ami => 'ami-6e164b0e')
    set!('us-west-2'.disable_camel!, :ami => 'ami-e1289181')
  end
end

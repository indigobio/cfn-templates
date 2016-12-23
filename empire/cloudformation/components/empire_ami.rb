SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_empire_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-66889f71')
    set!('us-east-2'.disable_camel!, :ami => 'ami-29c79d4c')
    set!('us-west-1'.disable_camel!, :ami => 'ami-74782914')
    set!('us-west-2'.disable_camel!, :ami => 'ami-e575c285')
  end
end

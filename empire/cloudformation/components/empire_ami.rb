SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_empire_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-53a3a339')
    set!('us-west-1'.disable_camel!, :ami => 'ami-c57f0da5')
    set!('us-west-2'.disable_camel!, :ami => 'ami-e901e889')
  end
end

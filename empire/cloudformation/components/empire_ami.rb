SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_empire_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-f3be8be4')
    set!('us-east-2'.disable_camel!, :ami => 'ami-95603af0')
    set!('us-west-1'.disable_camel!, :ami => 'ami-99f8adf9')
    set!('us-west-2'.disable_camel!, :ami => 'ami-8012bfe0')
  end
end

SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_empire_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-04cade13')
    set!('us-east-2'.disable_camel!, :ami => 'ami-90c79df5')
    set!('us-west-1'.disable_camel!, :ami => 'ami-61550401')
    set!('us-west-2'.disable_camel!, :ami => 'ami-f7d06797')
  end
end

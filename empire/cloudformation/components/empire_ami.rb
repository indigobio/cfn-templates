SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_empire_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-1e1c0009')
    set!('us-east-2'.disable_camel!, :ami => 'ami-4cf5af29')
    set!('us-west-1'.disable_camel!, :ami => 'ami-2fecbd4f')
    set!('us-west-2'.disable_camel!, :ami => 'ami-15d66775')
  end
end

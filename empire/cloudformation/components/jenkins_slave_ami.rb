SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_jenkins_slave_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-e54c08f2')
    set!('us-west-1'.disable_camel!, :ami => 'ami-5abaf93a')
    set!('us-west-2'.disable_camel!, :ami => 'ami-0860ab68')
  end
end

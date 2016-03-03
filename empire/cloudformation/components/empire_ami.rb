SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 14.04.3 Release 20150728
  mappings(:region_to_empire_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-bf6850d5')
    set!('us-west-1'.disable_camel!, :ami => 'ami-e4cfbf84')
    set!('us-west-2'.disable_camel!, :ami => 'ami-6a0de10a')
  end
end


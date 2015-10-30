SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 12.04.5 Release 20150728
  mappings(:region_to_precise_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-b5d58bd0') # ami-a7558fcc
    set!('us-west-1'.disable_camel!, :ami => 'ami-37503c57') # ami-039b6747
    set!('us-west-2'.disable_camel!, :ami => 'ami-7a51b349') # ami-2d6e601d
  end
end
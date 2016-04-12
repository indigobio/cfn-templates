SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 12.04.5 Release 20160315
  mappings(:region_to_precise_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-32564058')
    set!('us-west-1'.disable_camel!, :ami => 'ami-da5428ba')
    set!('us-west-2'.disable_camel!, :ami => 'ami-14a75374')
  end
end
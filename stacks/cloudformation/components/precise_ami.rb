SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 12.04.5 Release 20150728
  mappings(:region_to_precise_ami) do
    set!('us-east-1'._no_hump, :ami => 'ami-6b51e400') # ami-a7558fcc
    set!('us-west-1'._no_hump, :ami => 'ami-e77c82a3') # ami-039b6747
    set!('us-west-2'._no_hump, :ami => 'ami-bb0d188b') # ami-2d6e601d
    set!('eu-west-1'._no_hump, :ami => 'ami-42722635')
    set!('eu-central-1'._no_hump, :ami => 'ami-38b8bd25')
  end
end



SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now. Currently based on 12.04.5 Release 20150728
  mappings(:region_to_precise_ami) do
    set!('us-east-1'._no_hump, :ami => 'ami-ddd2bdb8') # ami-a7558fcc
    set!('us-west-1'._no_hump, :ami => 'ami-dd35cf99') # ami-039b6747
    set!('us-west-2'._no_hump, :ami => 'ami-a30c1193') # ami-2d6e601d
    set!('eu-west-1'._no_hump, :ami => 'ami-42722635')
    set!('eu-central-1'._no_hump, :ami => 'ami-38b8bd25')
  end
end

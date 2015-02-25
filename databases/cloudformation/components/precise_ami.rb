SparkleFormation.build do
  # For simplicity's sake we'll just use hvm:ebs-ssd AMIs for now.
  mappings(:region_to_precise_ami) do
    set!('us-east-1'._no_hump, :ami => 'ami-e6296b8e') # 12.04.5 Release 20150204
    set!('us-west-1'._no_hump, :ami => 'ami-fa5843bf')
    set!('us-west-2'._no_hump, :ami => 'ami-f78bd0c7')
    set!('eu-west-1'._no_hump, :ami => 'ami-c75bd5b0')
    set!('eu-central-1'._no_hump, :ami => 'ami-18cbf805')
  end
end
SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'._no_hump, :ami => 'ami-5fe81d34')
    set!('us-west-1'._no_hump, :ami => 'ami-0d6d8749')
    set!('us-west-2'._no_hump, :ami => 'ami-73b08843')
    set!('eu-west-1'._no_hump, :ami => 'ami-43691734')
    set!('eu-central-1'._no_hump, :ami => 'ami-6278407f')
  end
end
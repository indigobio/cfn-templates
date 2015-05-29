SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'._no_hump, :ami => 'ami-c8c0d3a0')
    set!('us-west-1'._no_hump, :ami => 'ami-af04eaeb')
    set!('us-west-2'._no_hump, :ami => 'ami-adf8cb9d')
    set!('eu-west-1'._no_hump, :ami => 'ami-1b97fd6c')
    set!('eu-central-1'._no_hump, :ami => 'ami-60615f7d')
  end
end
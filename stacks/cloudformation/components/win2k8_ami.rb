SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Core-2015.05.13
    set!('us-east-1'._no_hump, :ami => 'ami-26d3c04e')
    set!('us-west-1'._no_hump, :ami => 'ami-9b08e6df')
    set!('us-west-2'._no_hump, :ami => 'ami-43f5c673')
    set!('eu-west-1'._no_hump, :ami => 'ami-8990fafe')
  end
end
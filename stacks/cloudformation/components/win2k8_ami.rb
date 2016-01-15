SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'.disable_camel!, :ami => 'ami-4d0c2927')
    set!('us-west-1'.disable_camel!, :ami => 'ami-b41266d4')
    set!('us-west-2'.disable_camel!, :ami => 'ami-3c879d5d')
  end
end

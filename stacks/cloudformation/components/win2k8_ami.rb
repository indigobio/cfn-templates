SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'.disable_camel!, :ami => 'ami-315f625b')
    set!('us-west-1'.disable_camel!, :ami => 'ami-29077749')
    set!('us-west-2'.disable_camel!, :ami => 'ami-2c57b54c')
  end
end

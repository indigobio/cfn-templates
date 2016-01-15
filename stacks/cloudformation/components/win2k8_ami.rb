SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'.disable_camel!, :ami => 'ami-b4e2c7de')
    set!('us-west-1'.disable_camel!, :ami => 'ami-5a1d693a')
    set!('us-west-2'.disable_camel!, :ami => 'ami-2cbda74d')
  end
end

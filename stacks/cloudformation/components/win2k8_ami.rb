SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'.disable_camel!, :ami => 'ami-8c7b2a9b')
    set!('us-west-1'.disable_camel!, :ami => 'ami-acd890cc')
    set!('us-west-2'.disable_camel!, :ami => 'ami-d49035b4')
  end
end

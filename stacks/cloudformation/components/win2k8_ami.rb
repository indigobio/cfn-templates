SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'.disable_camel!, :ami => 'ami-0bdfd261')
    set!('us-west-1'.disable_camel!, :ami => 'ami-dc5727bc')
    set!('us-west-2'.disable_camel!, :ami => 'ami-48f11c28')
  end
end

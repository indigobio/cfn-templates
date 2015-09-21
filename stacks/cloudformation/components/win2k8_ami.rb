SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'.disable_camel!, :ami => 'ami-3bd17a50')
    set!('us-west-1'.disable_camel!, :ami => 'ami-ede01ea9')
    set!('us-west-2'.disable_camel!, :ami => 'ami-59c3c969')
    set!('eu-west-1'.disable_camel!, :ami => 'ami-82e6b4f5')
    set!('eu-central-1'.disable_camel!, :ami => 'ami-0a181f17')
  end
end

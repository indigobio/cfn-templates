SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'.disable_camel!, :ami => 'ami-d86797a2')
    set!('us-east-2'.disable_camel!, :ami => 'ami-335a7756')
    set!('us-west-1'.disable_camel!, :ami => 'ami-40625220')
    set!('us-west-2'.disable_camel!, :ami => 'ami-d9ef16a1')
  end
end

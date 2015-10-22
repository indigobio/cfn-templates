SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'.disable_camel!, :ami => 'ami-2194c844')
    set!('us-west-1'.disable_camel!, :ami => 'ami-4fea290b')
    set!('us-west-2'.disable_camel!, :ami => 'ami-22896b11')
    set!('eu-west-1'.disable_camel!, :ami => 'ami-872f0ff0')
    set!('eu-central-1'.disable_camel!, :ami => 'ami-98656585')
  end
end

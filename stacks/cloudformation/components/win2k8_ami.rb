SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'.disable_camel!, :ami => 'ami-13eab576')
    set!('us-west-1'.disable_camel!, :ami => 'ami-5f23e01b')
    set!('us-west-2'.disable_camel!, :ami => 'ami-6410f257')
    set!('eu-west-1'.disable_camel!, :ami => 'ami-872f0ff0')
    set!('eu-central-1'.disable_camel!, :ami => 'ami-98656585')
  end
end

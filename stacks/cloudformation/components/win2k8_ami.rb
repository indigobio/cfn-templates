SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'.disable_camel!, :ami => 'ami-e3cf9386')
    set!('us-west-1'.disable_camel!, :ami => 'ami-8df536c9')
    set!('us-west-2'.disable_camel!, :ami => 'ami-feee0ccd')
    set!('eu-west-1'.disable_camel!, :ami => 'ami-872f0ff0')
    set!('eu-central-1'.disable_camel!, :ami => 'ami-98656585')
  end
end

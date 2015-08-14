SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    # 	Windows_Server-2008-R2_SP1-English-64Bit-Base
    set!('us-east-1'._no_hump, :ami => 'ami-41b96e2a')
    set!('us-west-1'._no_hump, :ami => 'ami-eb42b1af')
    set!('us-west-2'._no_hump, :ami => 'ami-937173a3')
    set!('eu-west-1'._no_hump, :ami => 'ami-98004eef')
    set!('eu-central-1'._no_hump, :ami => 'ami-18be8405')
  end
end

SparkleFormation.build do
  mappings(:region_to_win2k8_ami) do
    set!('us-east-1'._no_hump, :ami => 'ami-188ac270') # 2015.02.11, released 04/03/2012
    set!('us-west-1'._no_hump, :ami => 'ami-86baa1c3')
    set!('us-west-2'._no_hump, :ami => 'ami-05c6e335')
    set!('eu-west-1'._no_hump, :ami => 'ami-01b83376')
  end
end
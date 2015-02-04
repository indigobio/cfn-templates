SparkleFormation.build do

  mappings.ami_to_region_map do
    set!('us-east-1', :ami => 'ami-24498a4c')
    set!('us-west-2', :ami => 'ami-2da7d41d')
  end

end
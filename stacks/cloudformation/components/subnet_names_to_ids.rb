lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc
SparkleFormation.build do
  mappings(:subnet_names_to_ids) do
    lookup.get_private_subnets(vpc).each do |n|
      set!(n[:name].disable_camel!, :id => n[:id])
    end
  end
end
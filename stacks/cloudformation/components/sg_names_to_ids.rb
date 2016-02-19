lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc
SparkleFormation.build do
  mappings(:sg_names_to_ids) do
    lookup.get_security_groups(vpc, '*').each do |sg|
      set!(sg[:name].disable_camel!, :id => sg[:id])
    end
  end
end
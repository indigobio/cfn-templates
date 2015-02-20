SparkleFormation.dynamic(:subnet) do |_name, _config = {}|
  # _config[:az] must be set to an availability zone
  # _config[:type] is either :public or :private
  # _config[:route_tables] should be set to a list of route tables

  _config[:route_tables] ||= [ :default_route_table ]

  resources("#{_name}_subnet".gsub('-','_').to_sym) do
    type 'AWS::EC2::Subnet'
    properties do
      vpc_id ref!(:vpc)
      availability_zone _config[:az]
      cidr_block map!(:subnets_to_az, 'AWS::Region', "#{_config[:az]}_#{_config[:type]}".gsub('-','_').to_sym)
      tags _array(
        -> {
          key 'name'
          value join!(_name, map!(:subnets_to_az, 'AWS::Region', "#{_config[:az]}_#{_config[:type]}".gsub('-','_').to_sym), {:options => { :delimiter => '-' }})
        }
      )
    end
  end

  _config[:route_tables].each do |rt|
    resources("#{_name}_#{rt.to_s}_association".gsub('-','_').to_sym) do
      type 'AWS::EC2::SubnetRouteTableAssociation'
      properties do
        subnet_id ref!("#{_name}_subnet".gsub('-','_').to_sym)
        route_table_id ref!(rt)
      end
    end
  end
end
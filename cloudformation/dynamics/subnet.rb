SparkleFormation.dynamic(:subnet) do |_name, _config = {}|
  # _config[:az] must be set to an availability zone
  # _config[:type] is either :public or :private
  # _config[:route_tables] should be set to a list of route tables

  _config[:route_tables] ||= [ :default_route_table ]

  resources("#{_name}_subnet".to_sym) do
    type 'AWS::EC2::Subnet'
    properties do
      vpc_id ref!(:vpc)
      availability_zone _config[:az]
      cidr_block map!(:subnets_to_az, _config[:az]._no_hump, _config[:type])
      tags do
        key 'name'
        value join!(_name, map!(:subnets_to_az, _config[:az]._no_hump, _config[:type]), {:options => { :delimiter => '-' }})
      end
    end
  end

  resources("#{_name}_subnet_route_table".to_sym) do
    type 'AWS::EC2::RouteTable'
    properties do
      vpc_id ref!(:vpc)
    end
  end

  _config[:route_tables].each do |rt|
    resources("#{_name}_#{rt.to_s}_association".to_sym) do
      type 'AWS::EC2::SubnetRouteTableAssociation'
      properties do
        subnet_id ref!("#{_name}_subnet".to_sym)
        route_table_id rt
      end
    end
  end
end
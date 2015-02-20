SparkleFormation.build do
  resources(:igw) do
    type 'AWS::EC2::InternetGateway'
    properties do; end
  end

  resources(:vpc_igw_attachment) do
    type 'AWS::EC2::VPCGatewayAttachment'
    properties do
      internet_gateway_id ref!(:igw)
      vpc_id ref!(:vpc)
    end
  end

  resources(:default_route_table) do
    type 'AWS::EC2::RouteTable'
    vpc_id ref!(:vpc)
  end

  resources(:default_route_through_igw) do
    depends_on 'VpcIgwAttachment'
    type 'AWS::EC2::Route'
    properties do
      destination_cidr_block '0.0.0.0/0'
      gateway_id ref!(:igw)
      route_table_id ref!(:default_route_table)
    end
  end

  resources(:default_route_table) do
    type 'AWS::EC2::RouteTable'
    vpc_id ref!(:vpc)
  end
end
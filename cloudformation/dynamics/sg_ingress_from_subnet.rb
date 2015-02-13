SparkleFormation.dynamic(:sg_ingress_from_subnet) do |_name, _config={}|
  # _config[:target] must be set to a security group

  parameters("#{_name}_allowed_from".to_sym) do
    type 'String'
    allowed_pattern '^(\d{1,3}\.){3}\d{1,3}\/\d{1,2}$'
    description 'Networks (CIDR blocks) to allow traffic from'
    default _config[:address] || '0.0.0.0/0'
  end

  parameters("#{_name}_protocol".to_sym) do
    type 'String'
    allowed_values _array('tcp', 'udp')
    default _config[:proto] || 'tcp'
  end

  parameters("#{_name}_from_port".to_sym) do
    type 'Number'
    min_value '0'
    max_value '65536'
    default _config[:from_port] || '22'
  end

  parameters("#{_name}_to_port".to_sym) do
    type 'Number'
    min_value '0'
    max_value '65536'
    default _config[:to_port] || '22'
  end

  resources("#{_name}_security_group_ingress".to_sym) do
    type 'AWS::EC2::SecurityGroupIngress'
    properties do
      cidr_ip ref!("#{_name}_allowed_from".to_sym)
      ip_protocol ref!("#{_name}_protocol".to_sym)
      from_port ref!("#{_name}_from_port".to_sym)
      to_port ref!("#{_name}_to_port".to_sym)
      group_id attr!(_config[:target], 'GroupId')
    end
  end
end
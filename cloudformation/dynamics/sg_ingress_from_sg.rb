SparkleFormation.dynamic(:sg_ingress_from_sg) do |_name, _config={}|
  # TODO: combine this with sg_ingress_from_subnet
  # _config[:target_type] must be set to :vpc or :ec2
  # _config[:target] must be set to a security group

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
      source_security_group_id attr!(_config[:source], 'GroupId')
      ip_protocol ref!("#{_name}_protocol".to_sym)
      from_port ref!("#{_name}_from_port".to_sym)
      to_port ref!("#{_name}_to_port".to_sym)
      group_id attr!(_config[:target], 'GroupId')
    end
  end
end
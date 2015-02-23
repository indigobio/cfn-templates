SparkleFormation.dynamic(:sg_egress) do |_name, _config={}|

  resources("#{_name}_security_group_egress".to_sym) do
    type 'AWS::EC2::SecurityGroupEgress'
    properties do
      group_id attr!(_config[:source_sg], 'GroupId')
      ip_protocol _config[:ip_protocol]
      from_port _config[:from_port]
      to_port _config[:to_port]
      destination_security_group_id attr!(_config[:target_sg], 'GroupId')
    end
  end
end
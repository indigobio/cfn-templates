SparkleFormation.dynamic(:security_group) do |_name, _config|
  # _config[:vpc] applies this security group to a VPC if true
  # _config[:allow_icmp] allows inbound ICMP messages and echo replies
  # _config[:ingress_rules] and _config[:egress_rules] are arrays of hashes:
  #
  # [{ :cidr_ip => '0.0.0.0/0', ip_protocol => 'tcp', :from_port => '22', :to_port => '22' }]

  conditions.set!(
    "#{_name}_is_a_vpc_sg".to_sym,
      equals!(ref!("#{_name}_attach_to_vpc".to_sym), 'true')
  )

  parameters("#{_name}_attach_to_vpc".to_sym) do
    type 'String'
    allowed_values ['true', 'false']
    default _config.fetch(:vpc, 'true')
  end

  resources("#{_name}_sg".to_sym) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description "#{_name} security group"
      vpc_id if!("#{_name}_is_a_vpc_sg".to_sym, ref!(:vpc), no_value!)

      # This, alone, makes me want to drop this tool.
      ingress_rules = Array.new
      ingress_rules.concat registry!(:inbound_icmp) if _config.fetch(:allow_icmp, true)
      ingress_rules.concat _config[:ingress_rules] if _config.has_key?(:ingress_rules)
      security_group_ingress array!(
        *ingress_rules.map { |r| -> {
            cidr_ip r['cidr_ip']
            ip_protocol r['ip_protocol']
            from_port r['from_port']
            to_port r['to_port']
          }
        }
      )

      egress_rules = Array.new
      egress_rules.concat _config[:egress_rules] if _config.has_key?(:egress_rules)
      security_group_egress array!(
        *egress_rules.map { |r| -> {
            cidr_ip r['cidr_ip']
            ip_protocol r['ip_protocol']
            from_port r['from_port']
            to_port r['to_port']
          }
        }
      )
    end
  end
end

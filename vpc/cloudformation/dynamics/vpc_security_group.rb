SparkleFormation.dynamic(:vpc_security_group) do |_name, _config|

  # {
  #   "Type" : "AWS::EC2::SecurityGroup",
  #   "Properties" : {
  #     "GroupDescription" : String,
  #     "SecurityGroupEgress" : [ Security Group Rule, ... ],
  #     "SecurityGroupIngress" : [ Security Group Rule, ... ],
  #     "Tags" :  [ Resource Tag, ... ],
  #     "VpcId" : String
  #   }
  # }

  # _config[:allow_icmp] allows inbound ICMP messages and echo replies
  # _config[:ingress_rules] and _config[:egress_rules] are arrays of hashes:
  #
  # [{ :cidr_ip => '0.0.0.0/0', ip_protocol => 'tcp', :from_port => '22', :to_port => '22' }]

  resources("#{_name}_sg".gsub('-','_').to_sym) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description "#{_name} security group"
      vpc_id ref!(:vpc)

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
      tags _array(
        -> {
          key 'Name'
          value "#{_name}_sg".gsub('-','_').to_sym
        }
      )
    end
  end

  resources("#{_name}_sg_ingress".gsub('-','_').to_sym) do
    type 'AWS::EC2::SecurityGroupIngress'
    properties do
      source_security_group_id attr!("#{_name}_sg".gsub('-','_').to_sym, :group_id)
      ip_protocol '-1'
      from_port '-1'
      to_port '-1'
      group_id attr!("#{_name}_sg".gsub('-','_').to_sym, :group_id)
    end
  end
end

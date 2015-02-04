SparkleFormation.dynamic(:nat_instance) do |_name, _config|
  resources("#{_name}_nat_instance".to_sym) do
    type 'AWS::EC2::Instance'
    properties do
      image_id map!(:nat_ami_64, 'AWS::Region', :ami)
      instance_type _config[:nat_instance_type]
      key_name _config[:ssh_key_name]
      #subnet_id blah
      source_dest_check 'false'
      security_group_ids [ ref!("#{_name}_nat_instance_security_group".to_sym) ]
      tags _array(
        -> {
          key 'Name'
          value join!('indigo', '-', ref!('AWS::Region'), '-', _name, '-', 'NAT')
        }
      )
    end
  end

  # TODO: The following resources should probably be declared in the high-level
  # template, or at least elsewhere than here.

  resources("#{_name}_nat_instance_security_group".to_sym) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description 'NAT instance security group'
    end
  end

  resources("#{_name}_nat_instance_security_group_ingress".to_sym) do
    type 'AWS::EC2::SecurityGroupIngress'
    properties do
      group_id attr!("#{_name}_nat_instance_security_group".to_sym, :group_id)
      cidr_ip '207.250.246.0/24'
      ip_protocol "tcp"
      from_port "22"
      to_port "22"
    end
  end
end


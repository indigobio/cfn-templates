SparkleFormation.dynamic(:nat_instance) do |_name, _config|

  parameters("#{_name}_nat_instance_type".to_sym) do
    type 'String'
    allowed_values ['t2.micro', 't2.small', 't2.medium', 'm3.medium', 'm3.large', 'c4.xlarge']
    default _config[:instance_type] || 'm3.medium'
  end

  resources("#{_name}_nat_instance".to_sym) do
    type 'AWS::EC2::Instance'
    properties do
      image_id map!(:region_to_nat_ami, 'AWS::Region', :ami)
      instance_type ref!("#{_name}_nat_instance_type".to_sym)
      key_name ref!(:ssh_key_pair)
      source_dest_check 'false'
      security_group_ids [ ref!(_config[:security_group].gsub('-', '_').to_sym) ]
      subnet_id ref!(_config[:subnet].gsub('-', '_').to_sym)

      tags _array(
        -> {
          key 'Name'
          value join!('indigo', ref!('AWS::Region'),  _name, 'NAT', {:options => { :delimiter => "-" }})
        }
      )
    end
  end
end


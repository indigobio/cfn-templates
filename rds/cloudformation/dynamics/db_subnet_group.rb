SparkleFormation.dynamic(:db_subnet_group) do |_name, _config = {}|

  resources("#{_name}_db_subnet_group".gsub('-','_').to_sym) do
    type 'AWS::RDS::DBSubnetGroup'
    properties do
      d_b_subnet_group_description "#{_name}_db_subnet_group".gsub('-','_').to_sym
      subnet_ids _config[:subnets]
      tags _array(
        -> {
          key 'Name'
          value "#{_name}_db_subnet_group".gsub('-','_').to_sym
        },
        -> {
          key 'Environment'
          value ENV['environment']
        }
      )
    end
  end
end

SparkleFormation.dynamic(:security_group) do |_name, _config = {}|
  # Use _config[:vpc] if you are applying this security group to a VPC

  resources("#{_name}_security_group".to_sym) do
    type 'AWS::EC2::SecurityGroup'
    properties do
      group_description "#{_name} security group"
      if _config.has_key?(:vpc)
        vpc_id ref!(_config[:vpc])
      end
    end
  end
end

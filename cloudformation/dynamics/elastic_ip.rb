SparkleFormation.dynamic(:elastic_ip) do |_name, _config|

  resources("#{_name}_elastic_ip".to_sym) do
    type 'AWS::EC2::EIP'
    properties do
      #domain 'vpc'
      #instance_id ref!(:nat_instance)
    end
  end

  resources("#{_name}_elastic_ip_association".to_sym) do
    type 'AWS::EC2::EIPAssociation'
    properties do
      #allocation_id attr!("#{_name}_nat_instance_elastic_ip".to_sym, :allocation_id)
      e_i_p ref!("#{_name}_elastic_ip".to_sym) # lol
      instance_id _config[:instance]
    end
  end
end
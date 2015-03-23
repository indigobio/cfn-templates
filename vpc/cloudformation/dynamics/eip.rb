SparkleFormation.dynamic(:eip) do |_name, _config = {}|

  # {
  #   "Type" : "AWS::EC2::EIP",
  #   "Properties" : {
  #     "InstanceId" : String,
  #     "Domain" : String
  #   }
  # }

  resources("#{_name.gsub('-','_')}_elastic_ip".to_sym) do
    type 'AWS::EC2::EIP'
    properties do
      domain 'vpc'
    end
  end

  outputs do
    eip_address do
      value ref!("#{_name.gsub('-','_')}_elastic_ip".to_sym)
      description "#{_name} Elastic IP Address"
    end
  end
end



SparkleFormation.build do

  # {
  #   "Type" : "AWS::RDS::DBParameterGroup",
  #   "Properties" : {
  #     "Description" : String,
  #     "Family" : String,
  #     "Parameters" : DBParameters,
  #     "Tags" : [ Resource Tag, ... ]
  #   }
  # }

  resources :rds_force_ssl do
    type 'AWS::RDS::DBParameterGroup'
    properties do
      description 'Force SSL connections'
      family 'postgres9.4'
      parameters do
        set!('rds.force_ssl'.disable_camel!, '1')
      end
    end
  end
end
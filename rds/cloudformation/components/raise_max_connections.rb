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

  resources :raise_max_connections do
    type 'AWS::RDS::DBParameterGroup'
    properties do
      description 'Raise max connections'
      family 'postgres9.4'
      parameters do
        set!('max_connections'.disable_camel!, "GREATEST({DBInstanceClassMemory/31457280},100)")
      end
    end
  end
end

SparkleFormation.dynamic(:dummy_log_group) do | _name |
  # {
  #   "Type" : "AWS::Logs::LogGroup",
  #   "Properties" : {
  #     "LogGroupName" : String,
  #     "RetentionInDays" : Integer
  #   }
  # }

  resources("#{_name}_dummy_log_group".to_sym) do
    type 'AWS::Logs::LogGroup'
    depends_on "#{_name}IamPolicy"
    properties do
      log_group_name "#{_name}_dummy"
      retention_in_days '1'
    end
  end
end
SparkleFormation.build do

  # {
  #   "Type" : "AWS::Logs::LogGroup",
  #   "Properties" : {
  #     "RetentionInDays" : Integer
  #   }
  # }

  resources "EmpireLogGroup" do
    type 'AWS::Logs::LogGroup'
    properties do
      retention_in_days 3
    end
  end
end
SparkleFormation.dynamic(:lambda_permission) do |_name, _config = {}|

  resources("#{_name}_lambda_permission".gsub('-', '_').to_sym) do
    type 'AWS::Lambda::Permission'
    properties do
      action 'lambda:InvokeFunction'
      principal 'sns.amazonaws.com'
      source_arn ref!(_config[:sns_topic])
      function_name attr!(_config[:lambda], :arn)
    end
  end
end

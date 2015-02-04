SparkleFormation.dynamic(:wait_handle) do |_name, _config|
  resources("wait_handle_#{_name}".to_sym) do
    type 'AWS::CloudFormation::WaitConditionHandle'
  end

  resources("wait_condition_#{_name}".to_sym) do
    type 'AWS::CloudFormation::WaitCondition'
    depends_on _config[:resource]
    properties do
      handle _config[:resource]
      timeout '600'
    end
  end
end

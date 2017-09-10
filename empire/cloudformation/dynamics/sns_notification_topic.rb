SparkleFormation.dynamic(:sns_notification_topic) do |_name, _config = {}|

  _config[:notification_topic_name] ||= "#{ENV['environment']}-#{_name}"
  _config[:protocol] ||= 'lambda'

  resources("#{_name}_sns_notification_topic".to_sym) do
    type 'AWS::SNS::Topic'
    properties do
      topic_name _config[:notification_topic_name]
      if _config.has_key?(:endpoint)
        subscription _array(
          -> {
            endpoint attr!(_config[:endpoint], :arn)
            protocol _config[:protocol]
          }
        )
      end
    end
  end

  outputs(:notification_topic) do
    description "SNS Topic ARN for ECS Instance Termination Notifications"
    value ref!("#{_name}_sns_notification_topic".to_sym)
  end
end

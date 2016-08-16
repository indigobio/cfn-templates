SparkleFormation.dynamic(:sns_notification_topic) do |_name, _config = {}|

  _config[:notification_topic_name] ||= "#{ENV['environment']}-ecs-instance-terminations"
  _config[:protocol] ||= 'lambda'

  parameters(:notification_topic_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'The name of the notification topic'
    constraint_description 'can only contain ASCII characters'
    default _config[:notification_topic_name]
  end

  resources("#{_name}_sns_notification_topic".to_sym) do
    type 'AWS::SNS::Topic'
    properties do
      topic_name ref!(:notification_topic_name)
      subscription _array(
        -> {
          endpoint attr!(_config[:endpoint], :arn)
          protocol _config[:protocol]
        }
      )
    end
  end

  outputs(:notification_topic) do
    description "SNS Topic ARN for ECS Instance Termination Notifications"
    value ref!("#{_name}_sns_notification_topic".to_sym)
  end
end

SparkleFormation.build do
  set!('AWSTemplateFormatVersion', '2010-09-09')

  conditions.set!(
      :notification_topic_has_name,
      not!(equals!(ref!(:notification_topic_name), 'none'))
  )

  parameters(:notification_topic_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'The name of the termination notification topic'
    constraint_description 'can only contain ASCII characters'
    default ENV['notification_topic']
  end

  resources(:notification_topic) do
    type 'AWS::SNS::Topic'
    properties do
      topic_name if!(:notification_topic_has_name, ref!(:notification_topic_name), no_value!)
      subscription _array(
                       -> {
                         endpoint attr!(:instance_termination_handler, :arn)
                         protocol 'lambda'
                       }
                   )
    end
  end

  outputs(:notification_topic) do
    description "SNS Topic ARN for Instance Termination Notifications"
    value ref!(:notification_topic)
  end
end

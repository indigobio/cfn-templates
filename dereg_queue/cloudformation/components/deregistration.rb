SparkleFormation.build do
  set!('AWSTemplateFormatVersion', '2010-09-09')

  conditions.set!(
    :dereg_topic_has_name,
    not!(equals!(ref!(:dereg_topic_name), 'none'))
  )

  parameters(:dereg_topic_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'The name of the deregistration notification topic'
    constraint_description 'can only contain ASCII characters'
    default ENV['notification_topic']
  end

  resources(:dereg_topic) do
    type 'AWS::SNS::Topic'
    properties do
      topic_name if!(:dereg_topic_has_name, ref!(:dereg_topic_name), no_value!)
      subscription _array(
        -> {
          endpoint attr!(:dereg_queue, :arn)
          protocol 'sqs'
        }
      )
    end
  end

  outputs(:dereg_topic) do
    description "SNS Topic ARN for Instance Deregistrations"
    value ref!(:dereg_topic)
  end
end

SparkleFormation.build do
  set!('AWSTemplateFormatVersion', '2010-09-09')

  conditions.set!(
    :dereg_topic_has_name,
    not!(equals!(ref!(:dereg_topic_name), 'none'))
  )

  parameters(:dereg_queue_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'When an instance is terminated, a notification will be sent to this queue'
    constraint_description 'can only contain ASCII characters'
    default 'instance_dereg_notifications'
  end

  parameters(:dereg_error_queue_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Dead letter queue for notifications when instance deregistraton fails'
    constraint_description 'can only contain ASCII characters'
    default 'instance_dereg_errors'
  end

  parameters(:dereg_topic_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'The name of the deregistration notification topic'
    constraint_description 'can only contain ASCII characters'
    default ENV['notification_topic']
  end

  resources(:dereg_queue) do
    type 'AWS::SQS::Queue'
    properties do
      queue_name ref!(:dereg_queue_name)
    end
  end

  resources(:dereg_error_queue) do
    type 'AWS::SQS::Queue'
    properties do
      queue_name ref!(:dereg_error_queue_name)
    end
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

  resources(:dereg_queue_policy) do
    type 'AWS::SQS::QueuePolicy'
    properties do
      policy_document do
        id 'DeregQueuePolicy'
        statement _array(
          -> {
            sid 'Allow-SendMessage-To-Queue-From-SNS-Topic'
            effect 'Allow'
            principal.set!("AWS", "*")
            action _array('sqs:SendMessage')
            resource '*'
            condition do
              arn_equals.set!('aws:SourceARN', ref!(:dereg_topic))
            end
          }
        )
      end
      queues _array(ref!(:dereg_queue))
    end
  end

  outputs(:dereg_topic) do
    description "SNS Topic ARN for Instance Deregistrations"
    value ref!(:dereg_topic)
  end

  outputs(:dereg_queue_url) do
    description "SQS Queue URL for Instance Deregistrations"
    value ref!(:dereg_queue)
  end

  outputs(:dereg_error_queue_url) do
    description "SQS Queue URL to record Instance Deregistration Errors"
    value ref!(:dereg_error_queue)
  end
end
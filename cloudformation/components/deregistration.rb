SparkleFormation.build do
  set!('AWSTemplateFormatVersion', '2010-09-09')

  resources(:dereg_queue) do
    type 'AWS::SNS::Queue'
  end

  resources(:dereg_error_queue) do
    type 'AWS::SNS::Queue'
  end

  resources(:dereg_topic) do
    type 'AWS::SNS::Topic'
    properties do
      subscription _array(
        -> {
          endpoint attr!(:dereg_queue, :arn)
        }
      )
    end
  end

  resources(:dereg_queue_policy) do
    type 'AWS::SQS::QueuePolicy'
    properties do
      policy_document do
        id :dereg_queue_policy
        statement do
          sid 'Allow-SendMessage-To-Queue-From-SNS-Topic'
          effect 'Allow'
          principal.set!("AWS", "*")
          action _array('sqs:SendMessage')
          resource '*'
          condition do
            arn_equals.set!('aws:SourceARN', ref!(:dereg_topic))
          end
        end
      end
    end
    queues _array(ref!(:dereg_queue))
  end
end
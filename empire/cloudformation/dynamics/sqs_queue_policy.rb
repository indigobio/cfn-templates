SparkleFormation.dynamic(:sqs_queue_policy) do |_name, _config = {}|

  resources("#{_name}_sns_queue_policy".to_sym) do
    type 'AWS::SQS::QueuePolicy'
    properties do
      queues _array( ref!(_config[:queue]) )
      policy_document do
        version '2012-10-17'
        id "#{_name}_queue_policy".to_sym
        statement _array(
          -> {
            effect 'Allow'
            principal '*'
            action _array( 'sqs:SendMessage' )
            resource '*'
            condition do
              arn_equals do
                data!['aws:SourceArn'] = ref!(_config[:topic])
              end
            end
          }
        )
      end
    end
  end
end
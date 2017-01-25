SparkleFormation.dynamic(:sqs_queue) do |_name, _config = {}|

  # {
  #   "Type" : "AWS::SQS::Queue",
  #   "Properties" : {
  #     "DelaySeconds": Integer,
  #     "MaximumMessageSize": Integer,
  #     "MessageRetentionPeriod": Integer,
  #     "QueueName": String,
  #     "ReceiveMessageWaitTimeSeconds": Integer,
  #     "RedrivePolicy": RedrivePolicy,
  #     "VisibilityTimeout": Integer
  #   }
  # }

  parameters("#{_name}_visibility_timeout".to_sym) do
    type 'Number'
    min_value 0
    max_value 43200
    default _config.fetch(:visibility_timeout, 1800)
  end

  resources("#{_name}_sqs_queue".to_sym) do
    type 'AWS::SQS::Queue'
    properties do
      visibility_timeout ref!("#{_name}_visibility_timeout".to_sym)
    end
  end
end
SparkleFormation.new('vpc').load(:deregistration).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an Amazon SNS topic that gets associated with Auto Scaling Groups.  Instance terminations result in
messages being posted to the SNS topic, which get stored in an Amazon SQS queue, to be picked up by a daemon
(see the deregister_nodes.rb script in the root of this repository).  Think RabbitMQ.

The deregistration daemon will remove instances' node and client objects from Chef, as well as from New Relic.
EOF
end
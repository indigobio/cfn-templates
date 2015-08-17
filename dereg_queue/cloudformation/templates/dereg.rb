require 'sparkle_formation'
require_relative('../../../utils/environment')

SparkleFormation.new('vpc').load(:deregistration).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an Amazon SNS topic that gets mapped to Auto Scaling Groups created in this region.  Instance terminations
result in messages being posted to the SNS topic, which get stored in an Amazon SQS queue.  The messages in the
queue are picked up by a daemon or an AWS lambda (see the deregister_nodes.rb script in the root of this repository).
The deregistration daemon will remove instances' node and client objects from Chef, as well as from New Relic.
EOF
end
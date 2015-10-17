require 'sparkle_formation'
require_relative('../../../utils/environment')

SparkleFormation.new('vpc').load(:sns, :bucket, :lambda).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an Amazon SNS topic that gets mapped to Auto Scaling Groups created in this region.  Instance terminations
result in messages being posted to the SNS topic, which get delivered to an AWS Lambda function.  The Lambda function
uses Chef client keys to delete node and client objects associated with terminated instances.
EOF
end
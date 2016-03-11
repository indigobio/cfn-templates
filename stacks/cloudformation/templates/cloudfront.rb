require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

SparkleFormation.new('webserver').load(:precise_ruby22_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing webserver instances.  Each instance is given an IAM instance
profile, which allows the instance to get objects from the Chef Validator Key Bucket.

Run this template while running the compute, reporter and custom_reporter templates.  Depends on the rabbitmq
and databases templates.
EOF

  dynamic!(:s3_bucket, 'assets', :acl => 'PublicRead')
  dynamic!(:s3_owner_write_bucket_policy, 'assets', :bucket => 'AssetsS3Bucket')
  dynamic!(:cloudfront_distribution, 'assets', :bucket => 'AssetsS3Bucket', :origin => "vanilla.#{ENV['public_domain']}")
end

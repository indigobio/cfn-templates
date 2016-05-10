require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

SparkleFormation.new('cloudfront').overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates a Cloudfront distribution and an S3 bucket to hold public assets.
EOF

  dynamic!(:s3_bucket, 'assets', :acl => 'PublicRead')
  dynamic!(:s3_owner_write_bucket_policy, 'assets', :bucket => 'AssetsS3Bucket')
  dynamic!(:cloudfront_distribution, 'assets', :bucket => 'AssetsS3Bucket', :origin => "vanilla.#{ENV['public_domain']}")
end

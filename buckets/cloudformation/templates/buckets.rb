require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

SparkleFormation.new('buckets').load(:git_rev_outputs).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates S3 buckets to hold data in transit.
EOF

  # Administrative buckets
  dynamic!(:s3_bucket, 'chef', :bucket_name => "ascent-#{ENV['environment']}-chef", :acl => 'BucketOwnerFullControl', :purpose => 'chef')
  dynamic!(:s3_owner_write_bucket_policy, 'chef', :bucket => 'ChefS3Bucket')

  dynamic!(:s3_bucket, 'lambda', :bucket_name => "ascent-#{ENV['environment']}-lambda", :acl => 'BucketOwnerFullControl', :purpose => 'lambda')
  dynamic!(:s3_owner_write_bucket_policy, 'lambda', :bucket => 'LambdaS3Bucket')

  # Buckets for use by services
  dynamic!(:s3_bucket, 'archival', :bucket_name => "ascent-#{ENV['environment']}-archival", :acl => 'BucketOwnerFullControl')
  dynamic!(:s3_owner_write_bucket_policy, 'archival', :bucket => 'AssetsS3Bucket')

  dynamic!(:s3_bucket, 'data', :bucket_name => "ascent-#{ENV['environment']}-data", :acl => 'BucketOwnerFullControl')
  dynamic!(:s3_owner_write_bucket_policy, 'data', :bucket => 'DataS3Bucket')

  dynamic!(:s3_bucket, 'extract', :bucket_name => "ascent-#{ENV['environment']}-extract", :acl => 'BucketOwnerFullControl')
  dynamic!(:s3_owner_write_bucket_policy, 'archival', :bucket => 'ExtractS3Bucket')

  dynamic!(:s3_bucket, 'raw', :bucket_name => "ascent-#{ENV['environment']}-raw", :acl => 'BucketOwnerFullControl')
  dynamic!(:s3_owner_write_bucket_policy, 'raw', :bucket => 'RawS3Bucket')

  dynamic!(:s3_bucket, 'customreports', :bucket_name => "ascent-#{ENV['environment']}-customreports", :acl => 'BucketOwnerFullControl')
  dynamic!(:s3_owner_write_bucket_policy, 'customreports', :bucket => 'CustomreportsS3Bucket')
end

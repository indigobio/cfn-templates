require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

SparkleFormation.new('buckets').overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates S3 buckets to hold data in transit.
EOF

  dynamic!(:s3_bucket, 'archival', :bucket_name => "asc-#{ENV['environment']}-archival", :acl => 'BucketOwnerFullControl')
  dynamic!(:s3_owner_write_bucket_policy, 'archival', :bucket => 'AssetsS3Bucket')

  dynamic!(:s3_bucket, 'extract', :bucket_name => "asc-#{ENV['environment']}-extract", :acl => 'BucketOwnerFullControl')
  dynamic!(:s3_owner_write_bucket_policy, 'archival', :bucket => 'ExtractS3Bucket')

  dynamic!(:s3_bucket, 'raw', :bucket_name => "asc-#{ENV['environment']}-raw", :acl => 'BucketOwnerFullControl')
  dynamic!(:s3_owner_write_bucket_policy, 'raw', :bucket => 'RawS3Bucket')

  dynamic!(:s3_bucket, 'customreports', :bucket_name => "asc-#{ENV['environment']}-customreports", :acl => 'BucketOwnerFullControl')
  dynamic!(:s3_owner_write_bucket_policy, 'customreports', :bucket => 'CustomreportsS3Bucket')
end
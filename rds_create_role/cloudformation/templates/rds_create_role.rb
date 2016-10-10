require 'sparkle_formation'
require_relative('../../../utils/environment')
require_relative('../../../utils/lookup')

ENV['private_sg'] ||= 'private_sg'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('vpc') do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an S3 bucket, an SNS topic, and an AWS Lambda.
EOF

  dynamic!(:s3_bucket, "#{ENV['org']}-#{ENV['environment']}-rds-create-role")

  dynamic!(:iam_policy, 'RdsCreateRole', :policy_statements => [ :describe_rds_db_instances])

  dynamic!(:iam_role, 'RdsCreateRole')

  dynamic!(:sns_topic,
           "#{ENV['org']}-#{ENV['environment']}-create-rds-db-instance",
           :subscriber => 'RdsCreateRoleLambdaFunction')

  dynamic!(:lambda_function,
           'rds-create-role',
           :timeout => 30,
           :bucket => 'RdsCreateRoleS3Bucket',
           :role => 'RdsCreateRoleIamRole',
           :security_groups => lookup.get_security_group_ids(vpc, ENV['private_sg']),
           :subnet_ids => lookup.get_private_subnet_ids(vpc))

  dynamic!(:lambda_permission,
           'rds-create-role',
           :sns_topic => "#{ENV['org']}-#{ENV['environment']}-create-rds-db-instance-sns-topic".gsub('-', '_').to_sym,
           :lambda => 'RdsCreateRoleLambdaFunction')

end
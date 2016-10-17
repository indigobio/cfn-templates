require 'sparkle_formation'
require_relative('../../../utils/environment')
require_relative('../../../utils/lookup')

ENV['private_sg'] ||= 'private_sg'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc
bucket = lookup.find_bucket(ENV['environment'], 'lambda')

SparkleFormation.new('rds_create_role_lambda_function') do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an AWS Lambda that creates non-privileged roles in an RDS instance upon CREATE_COMPLETE events.  Requires VPC membership.
EOF

  dynamic!(:iam_policy, 'RdsCreateRole', :policy_statements => [ :describe_rds_db_instances, :create_ec2_network_interface ])

  dynamic!(:iam_role, 'RdsCreateRole')

  # Totally a hack.  https://github.com/serverless/serverless/pull/1934
  dynamic!(:dummy_log_group, 'RdsCreateRole')

  dynamic!(:sns_topic,
           "#{ENV['org']}-#{ENV['environment']}-create-rds-db-instance",
           :subscriber => 'RdsCreateRoleLambdaFunction')

  dynamic!(:lambda_permission,
           'RdsCreateRole',
           :sns_topic => "#{ENV['org']}-#{ENV['environment']}-create-rds-db-instance-sns-topic".gsub('-', '_').to_sym,
           :lambda => 'RdsCreateRoleLambdaFunction')

  dynamic!(:lambda_function,
           'RdsCreateRole',
           :timeout => 30,
           :bucket => bucket,
           :key => 'rds_create_role/rds_create_role.zip',
           :handler => 'rds_create_role.lambda_handler',
           :role => 'RdsCreateRoleIamRole',
           :security_groups => lookup.get_security_group_ids(vpc, ENV['private_sg']),
           :subnet_ids => lookup.get_private_subnet_ids(vpc))

end
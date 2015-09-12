ENV['net_type'] ||= 'Private'
ENV['sg']       ||= 'private_sg'
ENV['run_list'] ||= 'role[base],role[couchbase_server]'

require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('couchbase').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates a single Couchbase server.  The instance is given an IAM instance profile, which
allows the instance to get objects from the Chef Validator Key Bucket.

Depends on the VPC template.
EOF

  dynamic!(:iam_instance_profile, 'default')
  dynamic!(:launch_config_chef_bootstrap, 'couchbase', :instance_type => 'm3.medium', :security_groups => lookup.get_security_groups(vpc), :chef_run_list => ENV['run_list'])
  dynamic!(:auto_scaling_group, 'couchbase', :launch_config => :couchbase_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)
end
ENV['net_type'] ||= 'Private'
ENV['sg'] ||= 'private_sg'

require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('assaymatic').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing assaymatic instances.  Each instance is given an IAM instance
profile, which allows the instance to get objects from the Chef Validator Key Bucket.

Run this template while running the compute, reporter and custom_reporter templates.  Depends on the rabbitmq
and databases templates.
EOF

  dynamic!(:iam_instance_profile, 'default')
  dynamic!(:launch_config_chef_bootstrap, 'assaymatic', :instance_type => 'm3.medium', :create_ebs_volumes => false, :security_groups => lookup.get_security_groups(vpc), :chef_run_list => 'role[base],role[assaymatic]')
  dynamic!(:auto_scaling_group, 'assaymatic', :launch_config => :assaymatic_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)
end

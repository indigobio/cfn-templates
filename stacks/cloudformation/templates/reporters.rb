ENV['net_type'] ||= 'Private'
ENV['sg'] ||= 'private_sg'

require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('reporters').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates auto scaling groups for backend reporters including report servers.  Each instance is
given an IAM instance profile, which allows the instance to get objects from the Chef Validator Key Bucket.

Run this template while running the compute and webserver templates.  Depends on the rabbitmq
and databases stacks.
EOF

  dynamic!(:iam_instance_profile, 'default')

  dynamic!(:launch_config_chef_bootstrap, 'reporter', :instance_type => 'm3.medium', :create_ebs_volumes => false, :security_groups => lookup.get_security_groups(vpc), :chef_run_list => 'role[base],role[reporter]')
  dynamic!(:auto_scaling_group, 'reporter', :launch_config => :reporter_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)

  dynamic!(:launch_config_chef_bootstrap, 'reportcatcher', :instance_type => 'm3.medium', :create_ebs_volumes => false, :security_groups => lookup.get_security_groups(vpc), :chef_run_list => 'role[base],role[reportcatcher]')
  dynamic!(:auto_scaling_group, 'reportcatcher', :launch_config => :reportcatcher_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)
end

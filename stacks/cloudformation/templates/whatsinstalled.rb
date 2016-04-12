require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type'] ||= 'Private'
ENV['sg']       ||= 'web_sg'
ENV['run_list'] ||= 'role[base],role[whatsinstalled]'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('whatsinstalled').load(:precise_ruby223_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling groups containing whatsinstalled instances.
Each instance is given an IAM instance profile, which allows the instance to get validator keys and encrypted
data bag secrets from the Chef validator key bucket.

Launch this template after launching the fileserver and assaymatic templates.  Launching this stack depends on
a VPC with a matching environment, assaymatic servers, and a file server.
EOF

  dynamic!(:iam_instance_profile, 'default', :policy_statements => [ :chef_bucket_access, :modify_route53 ])
  dynamic!(:launch_config_chef_bootstrap, 'whatsinstalled', :instance_type => 't2.small', :security_groups => lookup.get_security_group_ids(vpc), :chef_run_list => ENV['run_list'])
  dynamic!(:auto_scaling_group, 'whatsinstalled', :launch_config => :whatsinstalled_launch_config, :max_size => 1, :desired_capacity => 1, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)
end

ENV['net_type'] ||= 'Private'
ENV['sg']       ||= 'private_sg'
ENV['run_list'] ||= 'role[base],role[site_manager],role[nexus]'

require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('sitemanager').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling groups containing site (customer) management instances.
Each instance is given an IAM instance profile, which allows the instance to get validator keys and encrypted
data bag secrets from the Chef validator key bucket.

Launch this template after launching the fileserver and assaymatic templates.  Launching this stack depends on
a VPC with a matching environment, assaymatic servers, and a file server.
EOF

  dynamic!(:iam_instance_profile, 'default')

  dynamic!(:launch_config_chef_bootstrap, 'sitemanager', :instance_type => 't2.small', :security_groups => lookup.get_security_groups(vpc), :chef_run_list => ENV['run_list'])
  dynamic!(:auto_scaling_group, 'sitemanager', :launch_config => :sitemanager_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)
end

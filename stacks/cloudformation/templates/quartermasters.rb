ENV['net_type'] ||= 'Private'
ENV['sg']       ||= 'web_sg'
ENV['run_list'] ||= 'role[base],role[quartermaster]'

require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('quartermaster').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing quartermaster instances.  Each instance is given an IAM instance profile, which allows the instance to get validator keys and encrypted
data bag secrets from the Chef validator key bucket.

Launching this stack requires a VPC with a matching environment tag.  Chef will not work unless databases and file servers are up.
EOF

  dynamic!(:iam_instance_profile, 'default')
  dynamic!(:launch_config_chef_bootstrap, 'quartermaster', :instance_type => 'm3.medium', :create_ebs_volumes => false, :security_groups => lookup.get_security_groups(vpc), :chef_run_list => ENV['run_list'])
  dynamic!(:auto_scaling_group, 'quartermaster', :launch_config => :quartermaster_launch_config, :min_size => 1, :desired_capacity => 2, :max_size => 2, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)
end

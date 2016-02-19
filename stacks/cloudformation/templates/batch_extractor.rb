require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type'] ||= 'Private'
ENV['sg']       ||= 'private_sg'
ENV['run_list'] ||= 'role[base],role[batch_extractor]'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('batch_extractor').load(:precise_ruby22_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group for the batch extractor daemon.

Run this template while running the compute and webserver templates.  Depends on the rabbitmq and databases stacks.
EOF

  dynamic!(:iam_instance_profile, 'default', :policy_statements => [ :chef_bucket_access ])

  dynamic!(:launch_config_chef_bootstrap, 'batchextractor', :instance_type => 't2.small', :create_ebs_volumes => false, :security_groups => lookup.get_security_group_ids(vpc), :chef_run_list => ENV['run_list'])
  dynamic!(:auto_scaling_group, 'batchextractor', :launch_config => :batchextractor_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)
end
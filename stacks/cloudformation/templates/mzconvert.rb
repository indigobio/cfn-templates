ENV['net_type'] ||= 'Private'
ENV['sg'] ||= 'private_sg'

require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('mzconvert').load(:win2k8_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates auto scaling groups for mzconvert (windows) servers.  Each instance is also given an IAM instance
profile, which allows the instance to get objedcts from the Chef Validator Key Bucket.

Run this template while running the compute and webserver templates.  Depends on the rabbitmq and
database stacks.
EOF

  dynamic!(:iam_instance_profile, 'default')
  dynamic!(:launch_config_windows_bootstrap, 'mzconvert', :instance_type => 'm3.large', :create_ebs_volumes => false, :security_groups => lookup.get_security_groups(vpc), :chef_run_list => 'role[windows_base],role[mzconvert]')
  dynamic!(:auto_scaling_group, 'mzconvert', :launch_config => :mzconvert_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)
end

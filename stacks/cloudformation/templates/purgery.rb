ENV['net_type'] ||= 'Private'
ENV['sg'] ||= 'private_sg'

require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('daemons').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group for the purgery daemon.  The purgery daemon is only run during off-peak hours.
Each purgery instance is given an IAM instance profile, which allows the instance to get objects from the
Chef Validator Key Bucket.

Run this template while running the compute and webserver templates.  Depends on the rabbitmq
and databases stacks.
EOF

  dynamic!(:iam_instance_profile, 'default')

  dynamic!(:launch_config_chef_bootstrap, 'purgery', :instance_type => 't2.small', :create_ebs_volumes => false, :security_groups => lookup.get_security_groups(vpc), :chef_run_list => 'role[base]')
  dynamic!(:auto_scaling_group, 'purgery', :launch_config => :purgery_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)

  dynamic!(:scheduled_action, 'purgery_down', :autoscaling_group => :purgery_asg, :min_size => 0, :desired_capacity => 0, :max_size => 0, :recurrence => '0 6 * * *')
  dynamic!(:scheduled_action, 'purgery_up', :autoscaling_group => :purgery_asg, :min_size => 0, :desired_capacity => 1, :max_size => 1, :recurrence => '0 4 * * 1-5')
end
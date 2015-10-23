require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type']     ||= 'Private'
ENV['sg']           ||= 'private_sg'
ENV['volume_count'] ||= '8'
ENV['volume_size']  ||= '250'
ENV['run_list']     ||= 'role[base],role[tokumx_single]'

lookup = Indigo::CFN::Lookups.new
snapshots = lookup.get_snapshots
vpc = lookup.get_vpc

SparkleFormation.new('databases').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates a single TokuMX server. The instance has a number of EBS volumes attached for
persistent data storage.  Optionally, these EBS volumes may be initialized from snapshot.

The instance is given an IAM instance profile, which allows the instance to get objects
from the Chef Validator Key Bucket.

Depends on the VPC template.
EOF

  dynamic!(:iam_instance_profile, 'database', :policy_statements => [ :create_snapshots ])

  args = [
      'singledatabase',
      :iam_instance_profile => :database_iam_instance_profile,
      :iam_instance_role => :database_iam_instance_role,
      :instance_type => 't2.small',
      :create_ebs_volumes => true,
      :volume_count => ENV['volume_count'].to_i,
      :volume_size => ENV['volume_size'].to_i,
      :security_groups => lookup.get_security_groups(vpc),
      :chef_run_list => ENV['run_list']
  ]
  args.last.merge!(:snapshots => snapshots) unless snapshots.empty?
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group,
           'singledatabase',
           :launch_config => :singledatabase_launch_config,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => lookup.get_notification_topic,
           :min_size => 0,
           :max_size => 1,
           :desired_capacity => 1)
end

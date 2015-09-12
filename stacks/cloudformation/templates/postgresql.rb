ENV['volume_count'] ||= '2'
ENV['volume_size']  ||= '20'
ENV['net_type']     ||= 'Private'
ENV['sg']           ||= 'private_sg'
ENV['run_list']     ||= 'role[base],role[postgresql_server]'

require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc
snapshots = lookup.get_snapshots

SparkleFormation.new('databases').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates a single PostgreSQL server. The instance has a number of EBS volumes attached for
persistent data storage.  Optionally, these EBS volumes may be initialized from snapshot.

The instance is given an IAM instance profile, which allows the instance to get objects
from the Chef Validator Key Bucket.

Depends on the VPC template.
EOF

  dynamic!(:iam_instance_profile, 'database', :policy_statements => [ :create_snapshots ])

  args = [
      'postgresql',
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
           'postgresql',
           :launch_config => :postgresql_launch_config,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => lookup.get_notification_topic,
           :min_size => 0,
           :max_size => 1,
           :desired_capacity => 1)
end

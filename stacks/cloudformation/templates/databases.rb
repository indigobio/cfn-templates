ENV['net_type']     ||= 'Private'
ENV['sg']           ||= 'private_sg,web_sg'
ENV['volume_count'] ||= '8'
ENV['volume_size']  ||= '400'

require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

lookup = Indigo::CFN::Lookups.new
snapshots = lookup.get_snapshots
vpc = lookup.get_vpc

SparkleFormation.new('databases').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates a cluster of database instances in order, so that the third instance that is
bootstrapped with Chef will create a complete MongoDB / TokuMX replica set.

Each instance has a number of EBS volumes attached for persistent data storage.  Optionally,
these EBS volumes may be initialized from snapshot.

Each instance is given an IAM instance profile, which allows the instance to get objects
from the Chef Validator Key Bucket.

Launch this template while launching the rabbitmq and file server templates.  Depends on
the VPC template.
EOF

  dynamic!(:iam_instance_profile, 'database', :policy_statements => [ :create_snapshots ])

  # Two database cluster members
  args = [
    'database',
    :iam_instance_profile => :database_iam_instance_profile,
    :iam_instance_role => :database_iam_instance_role,
    :instance_type => 't2.small',
    :create_ebs_volumes => true,
    :volume_count => ENV['volume_count'].to_i,
    :volume_size => ENV['volume_size'].to_i,
    :security_groups => lookup.get_security_groups(vpc),
    :chef_run_list => 'role[base],role[tokumx_server]'
  ]
  args.last.merge!(:snapshots => snapshots) unless snapshots.empty?
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group,
           'database',
           :launch_config => :database_launch_config,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => lookup.get_notification_topic,
           :min_size => 1,
           :max_size => 2,
           :desired_capacity => 2)

  # Third database cluster member, depends on the first two.  The idea is that a chef run
  # will automatically set up the replicaset once the third database server comes online.
  args = [
    'thirddatabase',
    :iam_instance_profile => :database_iam_instance_profile,
    :iam_instance_role => :database_iam_instance_role,
    :instance_type => 't2.small',
    :create_ebs_volumes => true,
    :volume_count => ENV['volume_count'].to_i,
    :volume_size => ENV['volume_size'].to_i,
    :security_groups => lookup.get_security_groups(vpc),
    :chef_run_list => 'role[base],role[tokumx_server]'
  ]
  args.last.merge!(:snapshots => snapshots) unless snapshots.empty?
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group,
           'thirddatabase',
           :launch_config => :thirddatabase_launch_config,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => lookup.get_notification_topic,
           :min_size => 0,
           :max_size => 1,
           :desired_capacity => 1,
           :depends_on => 'DatabaseAsg')
end

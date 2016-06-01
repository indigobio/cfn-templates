require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type']         ||= 'Private'
ENV['sg']               ||= 'private_sg'
ENV['volume_count']     ||= '8'
ENV['volume_size']      ||= '250'
ENV['run_list']         ||= 'role[base],role[tokumx_server]'
ENV['arbiter_run_list'] ||= 'role[base],role[tokumx_arbiter]'

lookup = Indigo::CFN::Lookups.new
snapshots = lookup.get_snapshots
vpc = lookup.get_vpc

SparkleFormation.new('databases_arbiter').load(:precise_ruby223_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
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

  dynamic!(:iam_instance_profile, 'database', :policy_statements => [ :chef_bucket_access, :create_snapshots, :modify_route53 ])

  # Arbiter.  Comes up first because you can't set up a replica set on an arbiter,
  # so you want a real mongo server up last.
  args = [
    'arbiter',
    :iam_instance_profile => :database_iam_instance_profile,
    :iam_instance_role => :database_iam_instance_role,
    :instance_type => 't2.small',
    :create_ebs_volumes => true,
    :volume_count => 2,
    :volume_size => 10,
    :ebs_optimized => false,
    :security_groups => lookup.get_security_group_ids(vpc),
    :chef_run_list => ENV['arbiter_run_list']
  ]
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group,
           'arbiter',
           :launch_config => :arbiter_launch_config,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => lookup.get_notification_topic,
           :min_size => 0,
           :max_size => 1,
           :desired_capacity => 1)

  # First replica set member; depends on the arbiter.
  args = [
      'firstdatabase',
      :iam_instance_profile => :database_iam_instance_profile,
      :iam_instance_role => :database_iam_instance_role,
      :instance_type => 't2.small',
      :create_ebs_volumes => true,
      :volume_count => ENV['volume_count'].to_i,
      :volume_size => ENV['volume_size'].to_i,
      :security_groups => lookup.get_security_group_ids(vpc),
      :chef_run_list => ENV['run_list']
  ]
  args.last.merge!(:snapshots => snapshots) unless snapshots.empty?
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group,
           'firstdatabase',
           :launch_config => :firstdatabase_launch_config,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => lookup.get_notification_topic,
           :min_size => 0,
           :max_size => 1,
           :desired_capacity => 1,
           :depends_on => 'ArbiterAsg')

  # Second replica set member; depends on the first member.  Running
  # chef here will cause the replica set to initiate.
  args = [
      'seconddatabase',
      :iam_instance_profile => :database_iam_instance_profile,
      :iam_instance_role => :database_iam_instance_role,
      :instance_type => 't2.small',
      :create_ebs_volumes => true,
      :volume_count => ENV['volume_count'].to_i,
      :volume_size => ENV['volume_size'].to_i,
      :security_groups => lookup.get_security_group_ids(vpc),
      :chef_run_list => ENV['run_list']
  ]
  args.last.merge!(:snapshots => snapshots) unless snapshots.empty?
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group,
           'seconddatabase',
           :launch_config => :seconddatabase_launch_config,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => lookup.get_notification_topic,
           :min_size => 0,
           :max_size => 1,
           :desired_capacity => 1,
           :depends_on => 'FirstdatabaseAsg')
end

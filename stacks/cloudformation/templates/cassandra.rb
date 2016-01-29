require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type']       ||= 'Private'
ENV['sg']             ||= 'private_sg'
ENV['run_list']       ||= 'role[base],role[cassandra_server]'

lookup = Indigo::CFN::Lookups.new
snapshots = lookup.get_snapshots
vpc = lookup.get_vpc

SparkleFormation.new('cassandra').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates a cluster of Apache Cassandra instances in order.

Each instance is given an IAM instance profile, which allows the instance to get objects
from the Chef Validator Key Bucket.
EOF

  dynamic!(:iam_instance_profile, 'cassandra', :policy_statements => [ :chef_bucket_access, :modify_route53 ])

  # First Cassandra cluster member
  args = [
    'firstcassandra',
    :iam_instance_profile => :cassandra_iam_instance_profile,
    :iam_instance_role => :cassandra_iam_instance_role,
    :instance_type => 't2.medium',
    :create_ebs_volumes => false,
    :security_groups => lookup.get_security_groups(vpc),
    :chef_run_list => ENV['run_list']
  ]
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group,
           'firstcassandra',
           :launch_config => :firstcassandra_launch_config,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => lookup.get_notification_topic,
           :min_size => 1,
           :max_size => 1,
           :desired_capacity => 1)

  # Second Cassandra cluster member
  args = [
    'secondcassandra',
    :iam_instance_profile => :cassandra_iam_instance_profile,
    :iam_instance_role => :cassandra_iam_instance_role,
    :instance_type => 't2.medium',
    :create_ebs_volumes => false,
    :security_groups => lookup.get_security_groups(vpc),
    :chef_run_list => ENV['run_list']
  ]
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group,
           'secondcassandra',
           :launch_config => :secondcassandra_launch_config,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => lookup.get_notification_topic,
           :min_size => 1,
           :max_size => 1,
           :desired_capacity => 1,
           :depends_on => 'FirstcassandraAsg')

  # Third Cassandra cluster member
  args = [
    'thirdcassandra',
    :iam_instance_profile => :cassandra_iam_instance_profile,
    :iam_instance_role => :cassandra_iam_instance_role,
    :instance_type => 't2.medium',
    :create_ebs_volumes => false,
    :security_groups => lookup.get_security_groups(vpc),
    :chef_run_list => ENV['run_list']
  ]
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group,
           'thirdcassandra',
           :launch_config => :thirdcassandra_launch_config,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => lookup.get_notification_topic,
           :min_size => 1,
           :max_size => 1,
           :desired_capacity => 1,
           :depends_on => 'SecondcassandraAsg')

end

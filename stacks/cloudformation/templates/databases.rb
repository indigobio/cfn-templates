require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type']       ||= 'Private'
ENV['sg']             ||= 'private_sg'
ENV['volume_count']   ||= '8'
ENV['volume_size']    ||= '375'
ENV['run_list']       ||= 'role[base],role[tokumx_server]'
ENV['third_run_list'] ||= ENV['run_list'] # Override with tokumx_arbiter if desired.

lookup = Indigo::CFN::Lookups.new
snapshots = lookup.get_snapshots
vpc = lookup.get_vpc

SparkleFormation.new('databases').load(:precise_ruby223_ami, :subnet_names_to_ids, :sg_names_to_ids, :ssh_key_pair, :chef_validator_key_bucket).overrides do
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

  # First two database cluster members
  args = [
    'firstdatabase',
    :iam_instance_profile => :database_iam_instance_profile,
    :iam_instance_role => :database_iam_instance_role,
    :instance_type => 't2.small',
    :volume_count => ENV['volume_count'].to_i,
    :volume_size => ENV['volume_size'].to_i,
    :security_groups => lookup.get_security_group_names(vpc),
    :subnets => lookup.get_private_subnet_names(vpc)[0],
    :chef_run_list => ENV['run_list']
  ]
  args.last.merge!(:snapshots => snapshots) unless snapshots.empty?
  dynamic!(:ec2_instance, *args)  # First database cluster member

  args = [
    'seconddatabase',
    :iam_instance_profile => :database_iam_instance_profile,
    :iam_instance_role => :database_iam_instance_role,
    :instance_type => 't2.small',
    :volume_count => ENV['volume_count'].to_i,
    :volume_size => ENV['volume_size'].to_i,
    :security_groups => lookup.get_security_group_names(vpc),
    :subnets => lookup.get_private_subnet_names(vpc)[1],
    :chef_run_list => ENV['run_list']
  ]
  args.last.merge!(:snapshots => snapshots) unless snapshots.empty?
  dynamic!(:ec2_instance, *args)

  args = [
    'thirddatabase',
    :iam_instance_profile => :database_iam_instance_profile,
    :iam_instance_role => :database_iam_instance_role,
    :instance_type => 't2.small',
    :volume_count => ENV['volume_count'].to_i,
    :volume_size => ENV['volume_size'].to_i,
    :security_groups => lookup.get_security_group_names(vpc),
    :subnets => lookup.get_private_subnet_names(vpc)[-1],
    :chef_run_list => ENV['run_list'],
    :depends_on => %w( FirstdatabaseEc2Instance SeconddatabaseEc2Instance )
  ]
  args.last.merge!(:snapshots => snapshots) unless snapshots.empty?
  dynamic!(:ec2_instance, *args)
end

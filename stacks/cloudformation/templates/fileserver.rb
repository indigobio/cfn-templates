require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['volume_count'] ||= '2'
ENV['volume_size']  ||= '10'
ENV['net_type'] ||= 'Private'
ENV['sg']       ||= 'private_sg'
ENV['run_list'] ||= 'role[base],role[file_server]'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('fileserver').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling groups containing file server instances, each with a pair of EBS volumes to attach in a RAID-1
pair.  Each instance is given an IAM instance profile, which allows the instance to get validator keys and encrypted
data bag secrets from the Chef validator key bucket.

Launch this template while launching the databases.rb and rabbitmq.rb templates.  Launching this stack depends on
a VPC with a matching environment.
EOF

  dynamic!(:iam_instance_profile, 'default', :policy_statements => [ :chef_bucket_access, :modify_route53 ])

  dynamic!(:launch_config_chef_bootstrap, 'fileserver', :instance_type => 't2.small', :create_ebs_volumes => true, :volume_count => ENV['volume_count'].to_i, :volume_size => ENV['volume_size'].to_i, :security_groups => lookup.get_security_group_ids(vpc), :chef_run_list => ENV['run_list'])
  dynamic!(:auto_scaling_group, 'fileserver', :launch_config => :fileserver_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)

end

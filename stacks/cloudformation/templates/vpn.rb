require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type'] ||= 'Public'
ENV['sg']       ||= 'vpn_sg'
ENV['run_list'] ||= 'role[base],role[openvpn_as]'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('vpn').load(:precise_ruby223_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing a VPN instance.  Each instance is given an IAM instance profile,
which allows the instance to get objects from the Chef Validator Key Bucket.  Associates the VPN auto scaling
group with an elastic load balancer defined in the vpc template.

Depends on the VPC template.
EOF

  dynamic!(:iam_instance_profile, 'vpn', :policy_statements => [ :chef_bucket_access, :modify_route53 ])

  dynamic!(:iam_instance_profile, 'default')

  args = [
    'vpn',
    :iam_instance_profile => :vpn_iam_instance_profile,
    :iam_instance_role => :vpn_iam_instance_role,
    :instance_type => 't2.micro',
    :create_ebs_volumes => false,
    :security_groups => lookup.get_security_group_ids(vpc),
    :public_ips => true,
    :chef_run_list => ENV['run_list']
  ]
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group, 'vpn', :min_size => 0, :max_size => 1, :desired_capacity => 1, :launch_config => :vpn_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)
end

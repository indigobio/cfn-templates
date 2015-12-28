require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['lb_purpose'] ||= 'public_elb'
ENV['net_type']   ||= 'Private'
ENV['sg']         ||= 'nginx_sg'
ENV['run_list']   ||= 'role[base],role[loadbalancer]'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('nginx').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing nginx instances.  Each instance is given an IAM instance profile,
which allows the instance to get objects from the Chef Validator Key Bucket.  Associates the nginx auto scaling
group with an elastic load balancer defined in the vpc template.

Depends on the webserver, logstash, vpc, and custom_reporter templates.
EOF

  parameters(:load_balancer_purpose) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default ENV['lb_purpose'] || 'none'
    description 'Load Balancer Purpose tag to match, to associate nginx instances.'
    constraint_description 'can only contain ASCII characters'
  end

  dynamic!(:iam_instance_profile, 'default', :policy_statements => [ :chef_bucket_access, :modify_elbs ])
  dynamic!(:launch_config_chef_bootstrap, 'nginx', :instance_type => 't2.micro', :create_ebs_volumes => false, :security_groups => lookup.get_security_groups(vpc), :chef_run_list => ENV['run_list'], :extra_bootstrap => 'register_with_elb')
  dynamic!(:auto_scaling_group, 'nginx', :launch_config => :nginx_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)
end

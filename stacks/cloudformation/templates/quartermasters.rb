require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['lb_purpose'] ||= 'quartermaster_elb'
ENV['lb_name']    ||= "#{ENV['org']}-#{ENV['environment']}-#{ENV['region']}-quartermaster-elb"
ENV['net_type'] ||= 'Private'
ENV['sg']       ||= 'web_sg'
ENV['run_list'] ||= 'role[base],role[quartermaster]'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('quartermaster').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing quartermaster instances.  Each instance is given an IAM instance profile, which allows the instance to get validator keys and encrypted
data bag secrets from the Chef validator key bucket.

Launching this stack requires a VPC with a matching environment tag.  Chef will not work unless databases and file servers are up.
EOF

  parameters(:load_balancer_purpose) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default ENV['lb_purpose'] || 'none'
    description 'Load Balancer Purpose tag to match, to associate quartermaster instances.'
    constraint_description 'can only contain ASCII characters'
  end

  dynamic!(:elb, 'quartermaster',
           :listeners => [
               { :instance_port => '80', :instance_protocol => 'tcp', :load_balancer_port => '80', :protocol => 'tcp' }
           ],
           :security_groups => lookup.get_security_groups(vpc),
           :subnets => lookup.get_subnets(vpc),
           :lb_name => ENV['lb_name'],
           :scheme => 'internal'
  )

  dynamic!(:iam_instance_profile, 'default', :policy_statements => [ :modify_elbs ])
  dynamic!(:launch_config_chef_bootstrap, 'quartermaster', :instance_type => 'm3.medium', :create_ebs_volumes => false, :security_groups => lookup.get_security_groups(vpc), :chef_run_list => ENV['run_list'], :extra_bootstrap => 'register_with_elb')
  dynamic!(:auto_scaling_group, 'quartermaster', :launch_config => :quartermaster_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)

  dynamic!(:route53_record_set, 'quartermaster_elb', :record => 'quartermaster', :target => :quartermaster_elb, :domain_name => ENV['private_domain'], :attr => 'DNSName', :ttl => '60')
end

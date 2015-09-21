ENV['lb_purpose'] ||= 'assaymatic_lb'
ENV['lb_name']    ||= "#{ENV['org']}-#{ENV['environment']}-#{ENV['region']}-assaymatic-elb"
ENV['net_type']   ||= 'Private'
ENV['sg']         ||= 'private_sg'
ENV['run_list']   ||= 'role[base],role[assaymatic]'

require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('assaymatic').load(:precise_ruby22_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing assaymatic instances.  Each instance is given an IAM instance
profile, which allows the instance to get objects from the Chef Validator Key Bucket.

Run this template while running the compute, reporter and custom_reporter templates.  Depends on the rabbitmq
and databases templates.
EOF

  parameters(:load_balancer_purpose) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default ENV['lb_purpose'] || 'none'
    description 'Load Balancer Purpose tag to match, to associate nginx instances.'
    constraint_description 'can only contain ASCII characters'
  end

  dynamic!(:elb, 'assaymatic',
           :listeners => [
               { :instance_port => '8080', :instance_protocol => 'http', :load_balancer_port => '8080', :protocol => 'http' }
           ],
           :security_groups => lookup.get_security_groups(vpc),
           :subnets => lookup.get_subnets(vpc),
           :lb_name => ENV['lb_name'],
           :scheme => 'internal'
  )

  dynamic!(:iam_instance_profile, 'default', :policy_statements => [ :modify_elbs ])
  dynamic!(:launch_config_chef_bootstrap, 'assaymatic', :instance_type => 'm3.medium', :create_ebs_volumes => false, :security_groups => lookup.get_security_groups(vpc), :chef_run_list => ENV['run_list'], :extra_bootstrap => 'register_with_elb')
  dynamic!(:auto_scaling_group, 'assaymatic', :launch_config => :assaymatic_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)

  dynamic!(:route53_record_set, 'assaymatic_elb', :record => 'assaymatic', :target => :assaymatic_elb, :domain_name => ENV['private_domain'], :attr => 'DNSName', :ttl => '60')
end

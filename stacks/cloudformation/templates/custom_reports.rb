require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['lb_purpose'] ||= 'customreports_elb'
ENV['lb_name']    ||= "#{ENV['org']}-#{ENV['environment']}-cr-elb"
ENV['net_type'] ||= 'Private'
ENV['sg']       ||= 'web_sg'
ENV['run_list'] ||= 'role[base],role[custom_reports]'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('webserver').load(:precise_ruby223_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing webserver instances.  Each instance is given an IAM instance
profile, which allows the instance to get objects from the Chef Validator Key Bucket.

Run this template while running the compute, reporter and custom_reporter templates.  Depends on the rabbitmq
and databases templates.
EOF

  dynamic!(:elb, 'customreports',
           :listeners => [
               { :instance_port => '80', :instance_protocol => 'http', :load_balancer_port => '80', :protocol => 'http' }
           ],
           :security_groups => lookup.get_security_group_ids(vpc),
           :subnets => lookup.get_subnets(vpc),
           :lb_name => ENV['lb_name'],
           :idle_timeout => '600',
           :scheme => 'internal'
  )

  dynamic!(:iam_instance_profile, 'default', :policy_statements => [ :chef_bucket_access, :modify_elbs ])

  dynamic!(:launch_config_chef_bootstrap, 'customreports', :instance_type => 't2.small', :create_ebs_volumes => false, :security_groups => lookup.get_security_group_ids(vpc), :chef_run_list => ENV['run_list'])
  dynamic!(:auto_scaling_group, 'customreports', :launch_config => :customreports_launch_config, :subnets => lookup.get_subnets(vpc), :load_balancers => [ ref!('CustomreportsElb') ], :notification_topic => lookup.get_notification_topic)

  dynamic!(:route53_record_set, 'customreports_elb', :record => 'customreports', :target => :customreports_elb, :domain_name => ENV['private_domain'], :attr => 'DNSName', :ttl => '60')
end

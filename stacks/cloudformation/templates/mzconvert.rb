require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['lb_purpose'] ||= 'mzconvert_elb'
ENV['lb_name']    ||= "#{ENV['org']}-#{ENV['environment']}-mzconvert-elb"
ENV['net_type']   ||= 'Private'
ENV['sg']         ||= 'private_sg'
ENV['run_list']   ||= 'role[mzconvert]'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('mzconvert').load(:win2k8_ami, :ssh_key_pair, :chef_validator_key_bucket, :git_rev_outputs).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates auto scaling groups for mzconvert (windows) servers.  Each instance is also given an IAM instance
profile, which allows the instance to get objedcts from the Chef Validator Key Bucket.

Run this template while running the compute and webserver templates.  Depends on the rabbitmq and
database stacks.
EOF

  dynamic!(:elb, 'mzconvert',
           :listeners => [
             { :instance_port => '80', :instance_protocol => 'http', :load_balancer_port => '80', :protocol => 'http' },
           ],
           :security_groups => lookup.get_security_group_ids(vpc),
           :subnets => lookup.get_subnets(vpc),
           :lb_name => ENV['lb_name'],
           :scheme => 'internal',
           :idle_timeout => '600'
  )

  dynamic!(:iam_instance_profile, 'default', :policy_statements => [ :chef_bucket_access ])
  dynamic!(:launch_config_windows_bootstrap, 'mzconvert', :instance_type => 'm3.large', :create_ebs_volumes => false, :security_groups => lookup.get_security_group_ids(vpc), :chef_run_list => ENV['run_list'])
  dynamic!(:auto_scaling_group, 'mzconvert', :launch_config => :mzconvert_launch_config, :subnets => lookup.get_subnets(vpc), :load_balancers => [ ref!('MzconvertElb') ], :notification_topic => lookup.get_notification_topic)

  dynamic!(:route53_record_set, 'mzconvert_elb', :record => 'mzconvert', :target => :mzconvert_elb, :domain_name => ENV['private_domain'], :attr => 'DNSName', :ttl => '60')
end

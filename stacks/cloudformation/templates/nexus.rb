require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['lb_purpose'] ||= 'nexus_elb'
ENV['lb_name']    ||= "#{ENV['org']}-#{ENV['environment']}-nexus-elb"
ENV['net_type'] ||= 'Private'
ENV['sg']       ||= 'web_sg'
ENV['run_list'] ||= 'role[base],role[site_manager],role[nexus]'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('nexus').load(:precise_ruby223_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling groups containing site (customer) management instances.
Each instance is given an IAM instance profile, which allows the instance to get validator keys and encrypted
data bag secrets from the Chef validator key bucket.

Launch this template after launching the fileserver and assaymatic templates.  Launching this stack depends on
a VPC with a matching environment, assaymatic servers, and a file server.
EOF

  dynamic!(:elb, 'nexus',
           :listeners => [
               { :instance_port => '80', :instance_protocol => 'http', :load_balancer_port => '80', :protocol => 'http' },
               { :instance_port => '8080', :instance_protocol => 'http', :load_balancer_port => '8080', :protocol => 'http' }
           ],
           :security_groups => lookup.get_security_group_ids(vpc),
           :subnets => lookup.get_subnets(vpc),
           :lb_name => ENV['lb_name'],
           :idle_timeout => '300',
           :scheme => 'internal'
  )

  dynamic!(:iam_instance_profile, 'default', :policy_statements => [ :chef_bucket_access, :modify_elbs ])
  dynamic!(:launch_config_chef_bootstrap, 'nexus', :instance_type => 't2.small', :security_groups => lookup.get_security_group_ids(vpc), :chef_run_list => ENV['run_list'])
  dynamic!(:auto_scaling_group, 'nexus', :launch_config => :nexus_launch_config, :subnets => lookup.get_subnets(vpc), :load_balancers => [ ref!('NexusElb') ], :notification_topic => lookup.get_notification_topic)

  dynamic!(:route53_record_set, 'nexus_elb', :record => 'nexus', :target => :nexus_elb, :domain_name => ENV['private_domain'], :attr => 'DNSName', :ttl => '60')
end

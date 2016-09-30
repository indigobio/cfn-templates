require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['lb_purpose'] ||= 'public_elb'
ENV['net_type']   ||= 'Private'
ENV['sg']         ||= 'nginx_sg'
ENV['run_list']   ||= 'role[base],role[loadbalancer]'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc
elb = lookup.get_elb(ENV['lb_purpose'])
certs = lookup.get_ssl_certs
pfx = "#{ENV['org']}-#{ENV['environment']}"

SparkleFormation.new('nginx').load(:precise_ruby223_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing nginx instances.  Each instance is given an IAM instance profile,
which allows the instance to get objects from the Chef Validator Key Bucket.  Associates the nginx auto scaling
group with an elastic load balancer defined in the vpc template.

Depends on the webserver, logstash, vpc, and custom_reporter templates.
EOF

  parameters(:elb_ssl_certificate_id) do
    type 'String'
    allowed_values certs
    description 'SSL certificate to use with the elastic load balancer'
  end

  ENV['lb_name'] ||= elb.nil? ? "#{pfx}-public-elb" : elb

  dynamic!(:elb, 'public',
           :listeners => [
             { :instance_port => '80', :instance_protocol => 'tcp', :load_balancer_port => '80', :protocol => 'tcp' },
             { :instance_port => '443', :instance_protocol => 'tcp', :load_balancer_port => '443', :protocol => 'ssl', :ssl_certificate_id => ref!(:elb_ssl_certificate_id), :policy_names => ['ELBSecurityPolicy-2016-08'] }
           ],
           :policies => [
             { :instance_ports => ['80', '443'], :policy_name => 'EnableProxyProtocol', :policy_type => 'ProxyProtocolPolicyType', :attributes => [ { 'Name' => 'ProxyProtocol', 'Value' => true} ] }
           ],
           :security_groups => lookup.get_security_group_ids(vpc, 'public_elb_sg'),
           :idle_timeout => '600',
           :subnets => lookup.get_public_subnet_ids(vpc),
           :lb_name => ENV['lb_name'],
           :ssl_certificate_ids => certs
  )

  dynamic!(:iam_instance_profile, 'default', :policy_statements => [ :chef_bucket_access ])
  dynamic!(:launch_config_chef_bootstrap, 'nginx', :instance_type => 't2.micro', :create_ebs_volumes => false, :security_groups => lookup.get_security_group_ids(vpc), :chef_run_list => ENV['run_list'])
  dynamic!(:auto_scaling_group, 'nginx', :launch_config => :nginx_launch_config, :subnets => lookup.get_subnets(vpc), :load_balancers => [ ref!('PublicElb') ], :notification_topic => lookup.get_notification_topic)

  dynamic!(:route53_record_set, 'public_elb', :record => "#{ENV['lb_name']}", :target => :public_elb, :domain_name => ENV['public_domain'], :attr => 'CanonicalHostedZoneName', :ttl => '60')
end

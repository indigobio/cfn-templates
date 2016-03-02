require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type']       ||= 'Private'
ENV['sg']             ||= 'private_sg,web_sg'
ENV['volume_count']   ||= '8'
ENV['volume_size']    ||= '375'
ENV['run_list']       ||= 'role[base]'
ENV['third_run_list'] ||= ENV['run_list'] # Override with tokumx_arbiter if desired.

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('databases').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an Elasticache Cluster using the memcached storage engine, and associates a CNAME pointing
memcached.<domain> to it.  Depends on the VPC template.
EOF

  dynamic!(:elasticache_cluster, 'memcached', :nodes => '1', :subnets => lookup.get_private_subnet_ids(vpc), :security_groups => lookup.get_security_group_ids(vpc))
  dynamic!(:route53_record_set, 'memcached', :record => 'memcached', :target => :memcached_elasticache_cluster, :domain_name => ENV['private_domain'], :attr => 'ConfigurationEndpoint.Address', :ttl => '60')
end

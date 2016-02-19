require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type']             ||= 'Private'
ENV['sg']                   ||= 'nginx_sg'
ENV['allowed_cidr']         ||= ''
ENV['restore_rds_snapshot'] ||= 'false'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

snapshot = ENV['restore_rds_snapshot'] == 'false' ? false : lookup.get_latest_rds_snapshot(ENV['restore_rds_snapshot'])

SparkleFormation.new('empire').load(:engine_versions).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an RDS instance, running the postgresql engine.  Ties the RDS instance into a VPC's private subnets.
EOF

  dynamic!(:db_security_group, 'empire', :vpc => vpc, :security_group => lookup.get_security_group_ids(vpc), :allowed_cidr => Array.new(ENV['allowed_cidr'].split(',')))
  dynamic!(:db_subnet_group, 'empire', :subnets => lookup.get_subnets(vpc))
  dynamic!(:rds_db_instance, 'empire', :engine => 'postgres', :db_subnet_group => :empire_db_subnet_group, :db_security_groups => [ 'EmpireDbSecurityGroup' ], :db_snapshot_identifier => snapshot)

  dynamic!(:route53_record_set, 'empire_rds', :record => 'empire-rds', :target => :empire_rds_db_instance, :domain_name => ENV['private_domain'], :attr => 'Endpoint.Address', :ttl => '60')

end

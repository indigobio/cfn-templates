require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type']             ||= 'Public'
ENV['sg']                   ||= 'chronicle_sg'
ENV['restore_rds_snapshot'] ||= 'none'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

snapshot = ENV['restore_rds_snapshot'] == 'none' ? false : lookup.get_latest_rds_snapshot(ENV['restore_rds_snapshot'])

SparkleFormation.new('chronicle').load(:engine_versions, :force_ssl).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an RDS instance, running the postgresql engine.  Ties the RDS instance into a VPC's private subnets.
EOF

  dynamic!(:db_subnet_group, 'chronicle', :subnets => lookup.get_subnets(vpc))

  dynamic!(:public_rds_db_instance,
           'chronicle',
           :engine => 'postgres',
           :db_subnet_group => :chronicle_db_subnet_group,
           :vpc_security_groups => lookup.get_security_group_ids(vpc, ENV['sg']),
           :db_snapshot_identifier => snapshot,
           :db_parameter_group => 'RdsForceSsl')

  dynamic!(:route53_record_set, 'chronicle',
           :record => 'chronicle',
           :target => :chronicle_rds_db_instance,
           :domain_name => ENV['public_domain'],
           :attr => 'Endpoint.Address',
           :ttl => '60')
end

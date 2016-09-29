require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type']             ||= 'Public'
ENV['sg']                   ||= 'private_sg,web_sg,empire_sg'
ENV['allowed_cidr']         ||= '127.0.0.1/32'
ENV['restore_rds_snapshot'] ||= 'none'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

snapshot = ENV['restore_rds_snapshot'] == 'none' ? false : lookup.get_latest_rds_snapshot(ENV['restore_rds_snapshot'])

SparkleFormation.new('chronicle').load(:engine_versions, :force_ssl).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an RDS instance, running the postgresql engine.  Ties the RDS instance into a VPC's private subnets.
EOF

  dynamic!(:db_security_group,
           'chronicle',
           :vpc => vpc,
           :security_group => lookup.get_security_group_ids(vpc),
           :allowed_cidr => Array.new(ENV['allowed_cidr'].split(',')))

  dynamic!(:db_subnet_group, 'chronicle', :subnets => lookup.get_subnets(vpc))

  dynamic!(:rds_db_instance,
           'chronicle',
           :engine => 'postgres',
           :db_subnet_group => :chronicle_db_subnet_group,
           :db_security_groups => [ 'ChronicleDbSecurityGroup' ],
           :db_snapshot_identifier => snapshot,
           :db_parameter_group => 'RdsForceSsl',
           :publicly_accessible => true)

  dynamic!(:route53_record_set, 'chronicle',
           :record => 'chronicle',
           :target => :chronicle_rds_db_instance,
           :domain_name => ENV['public_domain'],
           :attr => 'Endpoint.Address',
           :ttl => '60')
end

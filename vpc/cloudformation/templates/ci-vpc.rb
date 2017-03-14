require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

lookup = Indigo::CFN::Lookups.new
azs = lookup.get_azs

SparkleFormation.new('vpc').load(:vpc_cidr_blocks, :igw, :git_rev_outputs).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
VPC with just public subnets.
EOF

  parameters(:allow_access_from) do
    type 'String'
    allowed_pattern "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
    default '127.0.0.1/32'
    description 'Network to allow remote access from. Note that the default of 127.0.0.1/32 effectively disables access.'
    constraint_description 'Must follow IP/mask notation (e.g. 192.168.1.0/24)'
  end

  dynamic!(:vpc, ENV['vpc_name'])

  azs.each do |az|
    dynamic!(:subnet, "public_#{az}", :az => az, :type => :public, :map_public_ip_on_launch => true)
  end

  dynamic!(:route53_hosted_zone, "#{ENV['private_domain'].gsub('.','_')}", :vpcs => [ { :id => ref!(:vpc), :region => ref!('AWS::Region') } ] )

  dynamic!(:vpc_security_group, 'remote_access',
           :ingress_rules => [
             { 'cidr_ip' => ref!(:allow_access_from), 'ip_protocol' => 'tcp', 'from_port' => '22', 'to_port' => '22'},
             { 'cidr_ip' => ref!(:allow_access_from), 'ip_protocol' => 'tcp', 'from_port' => '80', 'to_port' => '80'},
             { 'cidr_ip' => '0.0.0.0/0', 'ip_protocol' => 'tcp', 'from_port' => '443', 'to_port' => '443'},
             { 'cidr_ip' => ref!(:allow_access_from), 'ip_protocol' => 'tcp', 'from_port' => '3389', 'to_port' => '3389'},
           ],
           :allow_icmp => true
  )
end

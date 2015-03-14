require 'fog'
require 'sparkle_formation'

ENV['org'] ||= 'indigo'
ENV['environment'] ||= 'dr'
ENV['region'] ||= 'us-east-1'
pfx = "#{ENV['org']}-#{ENV['environment']}-#{ENV['region']}"

ENV['vpc_name'] ||= "#{pfx}-vpc"
ENV['cert_name'] ||= "#{pfx}-cert"
ENV['lb_name'] ||= "#{pfx}-public-elb"

# Find availability zones so that we don't create a VPC template that chokes when
# an AZ isn't capable of taking additional resources.

def extract(response)
  response.body if response.status == 200
end

connection = Fog::Compute.new({ :provider => 'AWS', :region => ENV['region'] })
azs = extract(connection.describe_availability_zones)['availabilityZoneInfo'].collect { |z| z['zoneName'] }

# Find a server certificate.

iam = Fog::AWS::IAM.new
cert = extract(iam.list_server_certificates)['Certificates'].collect { |c| c['Arn'] if c['ServerCertificateName'] == ENV['cert_name'] }.shift rescue nil

# Build the template.

SparkleFormation.new('vpc').load(:vpc_cidr_blocks, :igw, :ssh_key_pair, :nat_ami, :nat_instance_iam).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
This template creates a Virtual Private Cloud in one AWS region.  The VPC consists of public and private subnets
in each availability zone, and an autoscaling group of NAT instances, distributed across the public subnets
in the VPC.  This template will create security groups allowing access through the NAT instances.  If desired, the
template will create a security group allowing SSH access to the NAT instances to a specified CIDR block (e.g.
your home office).

CIDR blocks for VPCs and subnets are mapped to AWS regions:

  us-east-1 = 172.20.0.0/16
  us-west-1 = 172.22.0.0/16
  us-west-2 = 172.24.0.0/16
  eu-west-1 = 172.26.0.0/16
  eu-central-1 = 172.28.0.0/16

Subnets are /20 blocks.  Public subnets start from .0, while private subnets start from .240.
EOF

  parameters(:allow_ssh_from) do
    type 'String'
    allowed_pattern "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
    default '127.0.0.1/32'
    description 'Network to allow SSH from, to NAT instances. Note that the default effectively disables SSH access.'
    constraint_description 'Must follow IP/mask notation (e.g. 192.168.1.0/24)'
  end

  dynamic!(:vpc, ENV['vpc_name'])

  public_subnets = Array.new
  azs.each do |az|
    dynamic!(:subnet, "public_#{az}", :az => az, :type => :public)
    public_subnets << "public_#{az}_subnet".gsub('-','_').to_sym
    dynamic!(:subnet, "private_#{az}", :az => az, :type => :private)
  end

  # TODO: rename (or delete) this.  Replace it with a security group for a VPN server.
  dynamic!(:vpc_security_group, 'nat',
           :ingress_rules => [
             { 'cidr_ip' => ref!(:allow_ssh_from), 'ip_protocol' => 'tcp', 'from_port' => '22', 'to_port' => '22'}
           ],
           :allow_icmp => true
  )

  dynamic!(:vpc_security_group, 'public_elb',
           :ingress_rules => [
             { 'cidr_ip' => '0.0.0.0/0', 'ip_protocol' => 'tcp', 'from_port' => '80', 'to_port' => '80'},
             { 'cidr_ip' => '0.0.0.0/0', 'ip_protocol' => 'tcp', 'from_port' => '443', 'to_port' => '443'}
           ],
          :allow_icmp => false
  )

  dynamic!(:vpc_security_group, 'private', :ingress_rules => [])
  dynamic!(:vpc_security_group, 'nginx', :ingress_rules => [])

  dynamic!(:sg_ingress, 'public-elb-to-nginx-http', :source_sg => :public_elb_sg, :ip_protocol => 'tcp', :from_port => '80', :to_port => '80', :target_sg => :nginx_sg)
  dynamic!(:sg_ingress, 'public-elb-to-nginx-https', :source_sg => :public_elb_sg, :ip_protocol => 'tcp', :from_port => '443', :to_port => '443', :target_sg => :nginx_sg)
  dynamic!(:sg_ingress, 'nat-to-private-ssh', :source_sg => :nat_sg, :ip_protocol => '-1', :from_port => '-1', :to_port => '-1', :target_sg => :private_sg)
  dynamic!(:sg_ingress, 'private-to-nat-all', :source_sg => :private_sg, :ip_protocol => '-1', :from_port => '-1', :to_port => '-1', :target_sg => :nat_sg)

  dynamic!(:launch_config, 'nat_instances', :public_ips => true, :instance_id => :nat_instance, :security_groups => [:nat_sg])
  dynamic!(:auto_scaling_group, 'nat_instances', :launch_config => :nat_instances_launch_config, :subnets => public_subnets )

  dynamic!(:elb, 'public',
    :listeners => [
      { :instance_port => '80', :instance_protocol => 'http', :load_balancer_port => '80', :protocol => 'http' },
      { :instance_port => '443', :instance_protocol => 'https', :load_balancer_port => '443', :protocol => 'https', :ssl_certificate_id => cert, :policy_names => ['ELBSecurityPolicy-2015-02'] }
    ],
    :security_groups => [ 'PublicElbSg' ],
    :subnets => public_subnets,
    :lb_name => ENV['lb_name']
  )

  dynamic!(:route53_record_set, 'public_elb', :zone_name => 'ascentrecovery.net', :type => 'CNAME', :name => '*', :target => :public_elb, :attr => 'CanonicalHostedZoneName')
end

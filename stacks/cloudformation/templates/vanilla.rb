require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type'] ||= 'Private'
ENV['sg']       ||= 'private_sg'
ENV['run_list'] ||= 'role[base],role[couchbase_server]'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('vanilla').load(:precise_ruby223_ami, :subnet_names_to_ids, :sg_names_to_ids, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates a single server.  The instance is given an IAM instance profile, which
allows the instance to get objects from the Chef Validator Key Bucket.

Depends on the VPC template.
EOF
  dynamic!(:iam_instance_profile, 'default', :policy_statements => [ :chef_bucket_access, :modify_route53 ])
  dynamic!(:ec2_instance, 'vanilla', :security_groups => lookup.get_security_group_names(vpc, '*'), :default_security_group => lookup.get_security_group_names(vpc).first, :subnets => lookup.get_private_subnet_names(vpc))


  outputs do
    instance_address do
      description 'Private IP'
      value attr!(:vanilla_ec2_instance, :private_ip)
    end
    instance_dns do
      description 'Private DNS'
      value attr!(:vanilla_ec2_instance, :private_dns)
    end
    instance_az do
      description 'Availability Zone'
      value attr!(:vanilla_ec2_instance, :availability_zone)
    end
  end
end
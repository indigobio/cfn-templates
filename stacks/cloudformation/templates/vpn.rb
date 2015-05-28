require 'fog'
require 'sparkle_formation'

ENV['org'] ||= 'indigo'
ENV['environment'] ||= 'dr'
ENV['region'] ||= 'us-east-1'

ENV['notification_topic'] ||= "#{ENV['org']}-#{ENV['region']}-terminated-instances"
ENV['net_type'] ||= 'Public'
ENV['sg'] ||= 'vpn_sg'

Fog.credentials = {
    :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
    :region => ENV['region']
}

# Find subnets and security groups by VPC membership and network type.  These subnets
# and security groups will be passed into the ASG and launch config (respectively) so
# that the ASG knows where to launch instances.

def extract(response)
  response.body if response.status == 200
end

ec2 = Fog::Compute.new({ :provider => 'AWS' })

vpcs = extract(ec2.describe_vpcs)['vpcSet']
vpc = vpcs.find { |vpc| vpc['tagSet'].fetch('Environment', nil) == ENV['environment']}['vpcId']

subnets = extract(ec2.describe_subnets)['subnetSet']
subnets.collect! { |sn| sn['subnetId'] if sn['tagSet'].fetch('Network', nil) == ENV['net_type'] and sn['vpcId'] == vpc }.compact!

sgs = Array.new
ENV['sg'].split(',').each do |sg|
  found_sgs = extract(ec2.describe_security_groups)['securityGroupInfo']
  found_sgs.collect! { |fsg| fsg['groupId'] if fsg['tagSet'].fetch('Name', nil) == sg and fsg['vpcId'] == vpc }.compact!
  sgs.concat found_sgs
end

# Lodate the SNS notifications topic to let us know when instances are terminated
sns = Fog::AWS::SNS.new
topics = extract(sns.list_topics)['Topics']
topic = topics.find { |e| e =~ /#{ENV['notification_topic']}/ }

# Build the template.

SparkleFormation.new('vpn').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing a VPN instance.  Each instance is given an IAM instance profile,
which allows the instance to get objects from the Chef Validator Key Bucket.  Associates the VPN auto scaling
group with an elastic load balancer defined in the vpc template.

Depends on the VPC template.
EOF

  dynamic!(:iam_instance_profile, 'vpn', :policy_statements => [ :modify_route53 ])

  dynamic!(:iam_instance_profile, 'default')
  args = [
    'vpn',
    :iam_instance_profile => :vpn_iam_instance_profile,
    :iam_instance_role => :vpn_iam_instance_role,
    :instance_type => 't2.micro',
    :create_ebs_volumes => false,
    :security_groups => sgs,
    :public_ips => true,
    :chef_run_list => 'role[base],role[openvpn_as]'
  ]
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group, 'vpn', :min_size => 0, :max_size => 1, :desired_capacity => 1, :launch_config => :vpn_launch_config, :subnets => subnets, :notification_topic => topic)
end

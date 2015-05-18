require 'fog'
require 'sparkle_formation'

ENV['org'] ||= 'indigo'
ENV['environment'] ||= 'dr'
ENV['region'] ||= 'us-east-1'

ENV['notification_topic'] ||= "#{ENV['org']}-#{ENV['region']}-terminated-instances"
ENV['net_type'] ||= 'Public'
ENV['sg'] ||= 'vpn_sg'

# Find subnets and security groups by VPC membership and network type.  These subnets
# and security groups will be passed into the ASG and launch config (respectively) so
# that the ASG knows where to launch instances.

def extract(response)
  response.body if response.status == 200
end

ec2 = Fog::Compute.new({ :provider => 'AWS', :region => ENV['region'] })

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

# The dereg_queue template sets up an SQS queue that contains node termination news.
sns = Fog::AWS::SNS.new(:region => ENV['region'])
topics = extract(sns.list_topics)['Topics']
topic = topics.find { |e| e =~ /#{ENV['notification_topic']}/ }

# Build the template.

SparkleFormation.new('vpnp2p').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing nginx instances.  Each instance is given an IAM instance profile,
which allows the instance to get objects from the Chef Validator Key Bucket.  Associates the nginx auto scaling
group with an elastic load balancer defined in the vpc template.

Depends on the webserver, logstash, vpc, and custom_reporter templates.
EOF

  dynamic!(:iam_instance_profile, 'vpnp2p', :policy_statements => [ :modify_eips ])

  args = [
      'vpnp2p',
      :iam_instance_profile => :vpnp2p_iam_instance_profile,
      :iam_instance_role => :vpnp2p_iam_instance_role,
      :instance_type => 't2.micro',
      :create_ebs_volumes => false,
      :security_groups => sgs,
      :public_ips => true,
      :chef_run_list => "role[base],role[vpn-p2p-#{ENV['environment']}-#{ENV['region']}]"
  ]
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group, 'vpnp2p', :launch_config => :vpnp2p_launch_config, :subnets => subnets, :notification_topic => topic)
end

require 'fog'
require 'sparkle_formation'

ENV['org'] ||= 'indigo'
ENV['environment'] ||= 'dr'
ENV['region'] ||= 'us-east-1'
pfx = "#{ENV['org']}-#{ENV['environment']}-#{ENV['region']}"

ENV['lb_name'] ||= "#{pfx}-public-elb"
ENV['notification_topic'] ||= "#{ENV['org']}-#{ENV['region']}-terminated-instances"
ENV['net_type'] ||= 'Private'
ENV['sg'] ||= 'private_sg,nginx_sg'

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

# Find Elastic Load Balancers to attach to the nginx auto scaling group

elb = Fog::AWS::ELB.new
elb_descs = extract(elb.describe_load_balancers)['DescribeLoadBalancersResult']['LoadBalancerDescriptions']
lb = elb_descs.collect { |lb| lb['LoadBalancerName'] if lb['LoadBalancerName'] =~ /#{ENV['lb_name']}/ and lb['VPCId'] =~ /#{vpc}/ }.compact.shift

# The dereg_queue template sets up an SQS queue that contains node termination news.

sns = Fog::AWS::SNS.new
topics = extract(sns.list_topics)['Topics']
topic = topics.find { |e| e =~ /#{ENV['notification_topic']}/ }

# Build the template.

SparkleFormation.new('nginx').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an auto scaling group containing nginx instances.  Each instance is given an IAM instance profile,
which allows the instance to get objects from the Chef Validator Key Bucket.  Associates the nginx auto scaling
group with an elastic load balancer defined in the vpc template.

Depends on the webserver, logstash, vpc, and custom_reporter templates.
EOF

  dynamic!(:iam_instance_profile, 'default')
  dynamic!(:launch_config_chef_bootstrap, 'nginx', :instance_type => 't2.micro', :create_ebs_volumes => false, :security_groups => sgs, :chef_run_list => 'role[base],role[loadbalancer]', :extra_bootstrap => 'register_with_elb')
  dynamic!(:auto_scaling_group, 'nginx', :launch_config => :nginx_launch_config, :subnets => subnets, :notification_topic => topic, :load_balancer => lb)
end

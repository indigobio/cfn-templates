require 'fog'
require 'sparkle_formation'

ENV['org'] ||= 'indigo'
ENV['environment'] ||= 'dr'
ENV['region'] ||= 'us-east-1'

ENV['notification_topic'] ||= "#{ENV['org']}-#{ENV['region']}-terminated-instances"
ENV['net_type'] ||= 'Private'
ENV['sg'] ||= 'private_sg'

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

connection = Fog::Compute.new({ :provider => 'AWS' })

vpcs = extract(connection.describe_vpcs)['vpcSet']
vpc = vpcs.find { |vpc| vpc['tagSet'].fetch('Environment', nil) == ENV['environment']}['vpcId']

subnets = extract(connection.describe_subnets)['subnetSet']
subnets.collect! { |sn| sn['subnetId'] if sn['tagSet'].fetch('Network', nil) == ENV['net_type'] and sn['vpcId'] == vpc }.compact!

sgs = Array.new
ENV['sg'].split(',').each do |sg|
  found_sgs = extract(connection.describe_security_groups)['securityGroupInfo']
  found_sgs.collect! { |fsg| fsg['groupId'] if fsg['tagSet'].fetch('Name', nil) == sg and fsg['vpcId'] == vpc }.compact!
  sgs.concat found_sgs
end

# The dereg_queue template sets up an SQS queue that contains node termination news.

sns = Fog::AWS::SNS.new
topics = extract(sns.list_topics)['Topics']
topic = topics.find { |e| e =~ /#{ENV['notification_topic']}/ }

# Build the template.

SparkleFormation.new('mzconvert').load(:win2k8_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates auto scaling groups for mzconvert (windows) servers.  Each instance is also given an IAM instance
profile, which allows the instance to get objedcts from the Chef Validator Key Bucket.

Run this template while running the compute and webserver templates.  Depends on the rabbitmq and
database stacks.
EOF

  dynamic!(:iam_instance_profile, 'default')
  dynamic!(:launch_config_windows_bootstrap, 'mzconvert', :instance_type => 'm3.large', :create_ebs_volumes => false, :security_groups => sgs)
  dynamic!(:auto_scaling_group, 'mzconvert', :launch_config => :mzconvert_launch_config, :subnets => subnets, :notification_topic => topic)
end

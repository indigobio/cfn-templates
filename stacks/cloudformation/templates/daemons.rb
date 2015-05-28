require 'fog'
require 'sparkle_formation'

ENV['org'] ||= 'indigo'
ENV['environment'] ||= 'dr'
ENV['region'] ||= 'us-east-1'

ENV['notification_topic'] ||= "#{ENV['org']}-#{ENV['region']}-terminated-instances"
ENV['net_type'] ||= 'Private'
ENV['sg'] ||= 'private_sg,web_sg'

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

SparkleFormation.new('daemons').load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates auto scaling groups for backend daemons including reporters, purgery, etc.  Each instance is
given an IAM instance profile, which allows the instance to get objects from the Chef Validator Key Bucket.

Run this template while running the compute and webserver templates.  Depends on the rabbitmq
and databases stacks.
EOF

  dynamic!(:iam_instance_profile, 'default')

  dynamic!(:launch_config_chef_bootstrap, 'reporter', :instance_type => 'm3.medium', :create_ebs_volumes => false, :security_groups => sgs, :chef_run_list => 'role[base],role[reporter],role[reportcatcher]')
  dynamic!(:auto_scaling_group, 'reporter', :launch_config => :reporter_launch_config, :subnets => subnets, :notification_topic => topic)

  dynamic!(:launch_config_chef_bootstrap, 'customreports', :instance_type => 't2.small', :create_ebs_volumes => false, :security_groups => sgs, :chef_run_list => 'role[base],role[custom_reports]')
  dynamic!(:auto_scaling_group, 'customreports', :launch_config => :customreports_launch_config, :subnets => subnets, :notification_topic => topic)

  dynamic!(:launch_config_chef_bootstrap, 'purgery', :instance_type => 't2.small', :create_ebs_volumes => false, :security_groups => sgs, :chef_run_list => 'role[base],role[purgery]')
  dynamic!(:auto_scaling_group, 'purgery', :launch_config => :purgery_launch_config, :subnets => subnets, :notification_topic => topic)

  dynamic!(:launch_config_chef_bootstrap, 'cbs', :instance_type => 't2.small', :create_ebs_volumes => false, :security_groups => sgs, :chef_run_list => 'role[base],role[cbs_reporter],role[cbs_reportcatcher],role[cbs_summaries]')
  dynamic!(:auto_scaling_group, 'cbs', :launch_config => :cbs_launch_config, :subnets => subnets, :notification_topic => topic)

  dynamic!(:launch_config_chef_bootstrap, 'correlator', :instance_type => 't2.small', :create_ebs_volumes => false, :security_groups => sgs, :chef_run_list => 'role[base],role[correlator]')
  dynamic!(:auto_scaling_group, 'correlator', :launch_config => :cbs_launch_config, :subnets => subnets, :notification_topic => topic)
end

require 'fog'
require 'sparkle_formation'

ENV['org'] ||= 'indigo'
ENV['environment'] ||= 'dr'
ENV['region'] ||= 'us-east-1'

ENV['snapshots'] ||= ''
ENV['backup_id'] ||= ''

# Ignored if snapshots are supplied.
ENV['volume_count'] ||= '2'
ENV['volume_size'] ||= '20'

ENV['notification_topic'] ||= "#{ENV['org']}-#{ENV['region']}-terminated-instances"
ENV['net_type'] ||= 'Private'
ENV['sg'] ||= 'private_sg'

Fog.credentials = {
    :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
    :region => ENV['region']
}

def extract(response)
  response.body if response.status == 200
end

connection = Fog::Compute.new({ :provider => 'AWS', :region => ENV['region'] })

# Find subnets and security groups by VPC membership and network type.  These subnets
# and security groups will be passed into the ASG and launch config (respectively) so
# that the ASG knows where to launch instances.

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

# The user supplied a backup_id, so hunt for snapshots and supply them to the launch configs
# of each database ASG.

snapshots = Array.new(ENV['snapshots'].split(','))
unless ENV['backup_id'].empty?
  found_snaps = extract(connection.describe_snapshots)['snapshotSet'].select { |ss| ss['tagSet'].include?('backup_id')}
  what_i_want = found_snaps.collect { |ss| ss['snapshotId'] if ss['tagSet']['backup_id'].downcase.include?(ENV['backup_id'].downcase) }.compact
  snapshots.concat what_i_want
end

# The dereg_queue template sets up an SQS queue that contains node termination news.
sns = Fog::AWS::SNS.new(:region => ENV['region'])
topics = extract(sns.list_topics)['Topics']
topic = topics.find { |e| e =~ /#{ENV['notification_topic']}/ }

# Build the template.

stack = SparkleFormation.new('databases')
stack.load(:precise_ami, :ssh_key_pair, :chef_validator_key_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates a single PostgreSQL server. The instance has a number of EBS volumes attached for
persistent data storage.  Optionally, these EBS volumes may be initialized from snapshot.

The instance is given an IAM instance profile, which allows the instance to get objects
from the Chef Validator Key Bucket.

Depends on the VPC template.
EOF

  dynamic!(:iam_instance_profile, 'database', :policy_statements => [ :create_snapshots ])

  args = [
      'postgresql',
      :iam_instance_profile => :database_iam_instance_profile,
      :iam_instance_role => :database_iam_instance_role,
      :instance_type => 't2.small',
      :create_ebs_volumes => true,
      :volume_count => ENV['volume_count'].to_i,
      :volume_size => ENV['volume_size'].to_i,
      :security_groups => sgs,
      :chef_run_list => 'role[base],role[postgresql_server]'
  ]
  args.last.merge!(:snapshots => snapshots) unless snapshots.empty?
  dynamic!(:launch_config_chef_bootstrap, *args)

  dynamic!(:auto_scaling_group,
           'postgresql',
           :launch_config => :postgresql_launch_config,
           :subnets => subnets,
           :notification_topic => topic,
           :min_size => 0,
           :max_size => 1,
           :desired_capacity => 1)
end

require 'sparkle_formation'
require 'securerandom'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type']                 ||= 'Public'
ENV['sg']                       ||= 'remote_access_sg'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('empire').load(:jenkins_slave_ami, :ssh_key_pair).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
  I like pie.
EOF

  parameters(:docker_registry) do
    type 'String'
    default 'https://index.docker.io/v1/'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Docker private registry url'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:docker_user) do
    type 'String'
    default ''
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Docker username for private registry'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:docker_pass) do
    type 'String'
    default ''
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Docker password for private registry'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:docker_email) do
    type 'String'
    default ''
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Docker private registry email'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:docker_version) do
    type 'String'
    default '1.12.1-0'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Version of docker to install'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:ecs_agent_version) do
    type 'String'
    default 'v1.10.0'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Version of the AWS ECS agent to install'
    constraint_description 'can only contain ASCII characters'
  end

  dynamic!(:sns_notification_topic, 'jenkinsslaves', :endpoint => 'DeregisterEcsInstancesHandler')
  dynamic!(:lambda, 'ecs-instance-termination-handler', :sns_topic => 'JenkinsslavesSnsNotificationTopic')

  dynamic!(:ecs_cluster, 'jenkinsslaves')

  dynamic!(:iam_instance_profile, 'jenkinsslaves', :policy_statements => [ :jenkins_slave_policy_statements ])

  dynamic!(:launch_config_jenkins_slaves,
           'jenkinsslaves',
           :instance_type => 'c4.xlarge',
           :create_ebs_volume => true,
           :security_groups => lookup.get_security_group_ids(vpc, ENV['sg']),
           :bootstrap_files => 'jenkins_slave_bootstrap_files',
           :cluster => 'JenkinsslavesEcsCluster')

  dynamic!(:auto_scaling_group,
           'jenkinsslaves',
           :launch_config => :jenkinsslaves_launch_config,
           :desired_capacity => 2,
           :max_size => 2,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => 'JenkinsslavesSnsNotificationTopic')

end



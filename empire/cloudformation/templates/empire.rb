require 'sparkle_formation'
require 'securerandom'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type']                 ||= 'Private'
ENV['sg']                       ||= 'empire_sg'
ENV['empire_public_sg']         ||= 'empire_public_sg'
ENV['controller_public_sg']     ||= 'public_elb_sg'
ENV['controller_sg']            ||= 'nginx_sg'
ENV['lb_name']                  ||= "#{ENV['org']}-#{ENV['environment']}-empire-elb"
ENV['empire_database_user']     ||= 'empire'
ENV['empire_database_password'] ||= 'empirepass'
ENV['empire_token_secret']      ||= SecureRandom.hex
ENV['new_relic_server_labels']  ||= "Environment:#{ENV['environment']};Role:empire"
ENV['enable_datadog']           ||= 'true'
ENV['enable_sumologic']         ||= 'true'
ENV['sumologic_collector_name'] ||= "#{ENV['environment']}-collector-container"

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc

SparkleFormation.new('empire').load(:empire_ami, :ssh_key_pair, :git_rev_outputs).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates two auto scaling groups, two ECS clusters, and an ELB. One ASG runs the Empire API, while the other runs Empire Minions.
EOF

  parameters(:ecs_agent_version) do
    type 'String'
    default 'v1.14.3'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Docker tag to specify the version of Empire to run'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_version) do
    type 'String'
    default '0.12.0'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Docker tag to specify the version of Empire to run'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_elb_sg_public) do
    type 'String'
    default lookup.get_security_group_ids(vpc, ENV['empire_public_sg']).join(',')
    allowed_pattern "[\\x20-\\x7E]*"
    description 'A public security group that Empire can manage'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_elb_sg_private) do
    type 'String'
    default lookup.get_security_group_ids(vpc, ENV['sg']).join(',')
    allowed_pattern "[\\x20-\\x7E]*"
    description 'A private security group that Empire can manage'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_private_subnets) do
    type 'String'
    default lookup.get_private_subnet_ids(vpc).join(',')
    allowed_pattern "[\\x20-\\x7E]*"
    description 'I have no idea what this is about'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_public_subnets) do
    type 'String'
    default lookup.get_public_subnet_ids(vpc).join(',')
    allowed_pattern "[\\x20-\\x7E]*"
    description 'I have no idea what this is about'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_database_user) do
    type 'String'
    default ENV['empire_database_user']
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Master password for Empire RDS instance'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_database_password) do
    type 'String'
    default ENV['empire_database_password']
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Master password for Empire RDS instance'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_ami_repository) do
    type 'String'
    default 'https://github.com/indigobio/empire_ami.git'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'The Empire AMI repository. Used to clone the latest ansible playbooks.'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:ansible_playbook_branch) do
    type 'String'
    default 'master'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'The Empire AMI repository git branch. Used to clone the latest ansible playbooks.'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_scheduler) do
    type 'String'
    default ENV.fetch('scheduler', '')
    allowed_values ['', 'cloudformation']
    description 'Scheduler to use with Empire (native API, cloudformation)'
  end

  parameters(:empire_token_secret) do
    type 'String'
    default ENV['empire_token_secret']
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Master token secret whatever that is'
    constraint_description 'can only contain ASCII characters'
  end

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
    default '17.06.0~ce-0~ubuntu'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Version of docker to install'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:github_client_id) do
    type 'String'
    default ''
    allowed_pattern "[\\x20-\\x7E]*"
    description 'A github application client ID, for OAuth'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:github_client_secret) do
    type 'String'
    default ''
    allowed_pattern "[\\x20-\\x7E]*"
    description 'A github application client secret, for OAuth'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:github_organization) do
    type 'String'
    default 'indigobio'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'The github organization that the application ID has access to'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:internal_domain) do
    type 'String'
    default lookup.get_zone_id(ENV['private_domain'])
    allowed_pattern "[\\x20-\\x7E]*"
    description 'ID of internal hosted zone for Empire to manage Route53 records'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:elb_ssl_certificate_id) do
    type 'String'
    default ENV['cert']
    description 'SSL certificate to use with the elastic load balancer'
  end

  parameters(:new_relic_server_labels) do
    type 'String'
    default ENV['new_relic_server_labels']
    allowed_pattern "[\\x20-\\x7E]*"
    description 'New Relic labels for server monitoring'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:enable_datadog) do
    type 'String'
    allowed_values %w(true false)
    default ENV['enable_datadog']
    description 'Deploy the sumologic collector container to all instances'
  end

  parameters(:dd_agent_version) do
    type 'String'
    default 'latest'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Datadog container version to start'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:enable_sumologic) do
    type 'String'
    allowed_values %w(true false)
    default ENV['enable_sumologic']
    description 'Deploy the sumologic collector container to all instances'
  end

  parameters(:sumologic_collector_name) do
    type 'String'
    default ENV['sumologic_collector_name']
    allowed_pattern "[\\x20-\\x7E]*"
    description 'SumoLogic Collector Name used as the sourceCategory'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:enable_datadog) do
    type 'String'
    allowed_values %w(true false)
    default ENV['enable_datadog']
    description 'Deploy the datadog agent container to all instances'
  end

  parameters(:dd_agent_version) do
    type 'String'
    default 'latest'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Datadog container version to start'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:load_balancer_type) do
    type 'String'
    default 'alb'
    allowed_values %w(alb elb)
    description 'Type of load balancer that Empire will create for web processes'
  end

  # An ELB for Empire Controller instances.  Not managed by Empire, itself.
  dynamic!(:elb, 'empire',
    :listeners => [
      { :instance_port => '8080',
        :instance_protocol => 'tcp',
        :load_balancer_port => '443',
        :protocol => 'ssl',
        :ssl_certificate_id => ref!(:elb_ssl_certificate_id)
      }
    ],
    :security_groups => lookup.get_security_group_ids(vpc, ENV['controller_public_sg']),
    :subnets => lookup.get_public_subnet_ids(vpc),
    :scheme => 'internet-facing',
    :lb_name => ENV['lb_name'],
    :ssl_certificate_ids => ref!(:elb_ssl_certificate_id)
  )

  # S3 bucket, SNS topic and SQS queue for Empire's own CloudFormation scheduler.
  dynamic!(:s3_bucket, 'empireCustomResources')
  dynamic!(:sns_notification_topic, 'empireCustomResources', :endpoint => 'EmpireCustomResourcesSqsQueue', :protocol => 'sqs')
  dynamic!(:sns_notification_topic, 'empireEvents')
  dynamic!(:sqs_queue, 'empireCustomResources')
  dynamic!(:sqs_queue_policy, 'empireCustomResources',
           :queue => 'EmpireCustomResourcesSqsQueue',
           :topic => 'EmpireCustomResourcesSnsNotificationTopic'
          )


  # TODO: test removal of a service (do the ELBs go away?)
  # Our own instance termination handler.  May be deprecated by the cloudformation scheduler?
  dynamic!(:sns_notification_topic, 'empire', :endpoint => 'DeregisterEcsInstancesHandler')
  dynamic!(:lambda, 'ecs-instance-termination-handler', :sns_topic => 'EmpireSnsNotificationTopic')

  # A DNS CNAME pointing to the ELB, above.
  dynamic!(:route53_record_set,
           'empire_elb',
           :record => 'empire',
           :target => :empire_elb,
           :domain_name => ENV['public_domain'],
           :attr => 'CanonicalHostedZoneName',
           :ttl => '60')

  # Allow both clusters' ECS instances to signal bootstrap success / mark themselves unhealthy
  dynamic!(:iam_role, 'ecsinstance')
  dynamic!(:iam_policy, 'ecsinstance',
           :policy_statements => [ :ecs_instance_policy_statements ],
           :roles => [ 'EcsinstanceIamRole' ]
  )
  dynamic!(:iam_instance_profile, 'ecsinstance', :roles => [ 'EcsinstanceIamRole' ])

  # Empire controller service.
  dynamic!(:iam_role, 'empireService', :services => [ 'ecs.amazonaws.com', 'events.amazonaws.com', 'lambda.amazonaws.com' ])
  dynamic!(:iam_policy, 'empireService',
           :policy_statements => {
             :empire_service_role_policy_statements => {
               :cluster => 'EmpireControllerEcsCluster'
             }
           },
           :roles => [ 'EmpireServiceIamRole' ]
          )

  # Empire controller task definition.
  dynamic!(:iam_role, 'empireTaskDefinition', :services => [ 'ecs-tasks.amazonaws.com' ])
  dynamic!(:iam_policy, 'empireTaskDefinition',
           :policy_statements => {
             :empire_task_definition_policy_statements => {
               :custom_resources_bucket => 'EmpireCustomResourcesS3Bucket',
               :custom_resources_queue => 'EmpireCustomResourcesSqsQueue',
               :custom_resources_topic => 'EmpireCustomResourcesSnsNotificationTopic',
               :events_topic => 'EmpireEventsSnsNotificationTopic',
               :internal_domain => ref!(:internal_domain)
             }
           },
           :roles => [ 'EmpireTaskDefinitionIamRole']
          )

  dynamic!(:launch_config_empire,
           'controller',
           :instance_type => 't2.small',
           :iam_instance_profile => 'EcsinstanceIamInstanceProfile',
           :iam_role => 'EcsinstanceIamRole',
           :create_ebs_volume => true,
           :security_groups => lookup.get_security_group_ids(vpc, ENV['controller_sg']),
           :bootstrap_files => 'empire_controller_files',
           :cluster => 'EmpireControllerEcsCluster')

  dynamic!(:auto_scaling_group,
           'controller',
           :launch_config => :controller_launch_config,
           :desired_capacity => 2,
           :max_size => 3,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => 'EmpireSnsNotificationTopic')

  dynamic!(:ecs_cluster, 'empire_controller')

  dynamic!(:ecs_service,
           'empire_controller',
           :desired_count => 2,
           :ecs_cluster => 'EmpireControllerEcsCluster',
           :load_balancers => [
             { :container_name => 'empire_controller',
               :container_port => '8080',
               :load_balancer => 'EmpireElb' }
           ],
           :service_role => 'EmpireServiceIamRole',
           :service_policy => 'EmpireServiceIamPolicy',
           :task_definition => 'EmpireTaskDefinition',
           :auto_scaling_group => 'ControllerAsg')

  # Some notes are in order, here.  EMPIRE_GITHUB_CLIENT_ID and EMPIRE_GITHUB_CLIENT_SECRET need to be
  # OAuth keys that you can use to log into EMPIRE_GITHUB_ORGANIZATION as an OAuth App.
  # See http://empire.readthedocs.org/en/latest/production_best_practices/#securing-the-api
  dynamic!(:ecs_task_definition,
           'empire',
           :task_role => 'EmpireTaskDefinitionIamRole',
           :container_definitions => [
             {
               :name => 'empire_controller',
               :image => join!('remind101/empire', ref!(:empire_version), {:options => { :delimiter => ':'}}),
               :command => [ 'server', '--automigrate=true' ],
               :memory => 256,
               :port_mappings => [ { :container_port => '8080', :host_port => '8080' } ],
               :mount_points => [
                 { :source_volume => 'dockerSocket', :container_path => '/var/run/docker.sock', :read_only => false},
                 { :source_volume => 'dockerCfg', :container_path => '/root/.dockercfg', :read_only => true}
               ],
               :essential => true,
               :environment => [
                 { :name => 'AWS_REGION', :value => region! },
                 { :name => 'EMPIRE_CUSTOM_RESOURCES_TOPIC', :value => ref!(:empire_custom_resources_sns_notification_topic) },
                 { :name => 'EMPIRE_CUSTOM_RESOURCES_QUEUE', :value => ref!(:empire_custom_resources_sqs_queue) },
                 { :name => 'EMPIRE_DATABASE_URL', :value => join!('postgres://', ref!(:empire_database_user), ':', ref!(:empire_database_password), '@empire-rds.', ENV['private_domain'], '/empire') },
                 { :name => 'EMPIRE_EC2_SUBNETS_PRIVATE', :value => join!(lookup.get_private_subnet_ids(vpc), {:options => { :delimiter => ','}}) },
                 { :name => 'EMPIRE_EC2_SUBNETS_PUBLIC', :value => join!(lookup.get_public_subnet_ids(vpc), {:options => { :delimiter => ','}}) },
                 { :name => 'EMPIRE_ECS_CLUSTER', :value => ref!(:empire_minion_ecs_cluster) },
                 { :name => 'EMPIRE_ECS_LOG_DRIVER', :value => 'json-file' },
                 { :name => 'EMPIRE_ECS_SERVICE_ROLE', :value => ref!(:empire_service_iam_role) },
                 { :name => 'EMPIRE_ELB_VPC_ID', :value => vpc },
                 { :name => 'EMPIRE_ELB_SG_PRIVATE', :value => ref!(:empire_elb_sg_private) },
                 { :name => 'EMPIRE_ELB_SG_PUBLIC', :value => ref!(:empire_elb_sg_public) },
                 { :name => 'EMPIRE_ENVIRONMENT', :value => ENV['environment'] },
                 { :name => 'EMPIRE_EVENTS_BACKEND', :value => 'sns' },
                 { :name => 'EMPIRE_GITHUB_CLIENT_ID', :value => ref!(:github_client_id) },
                 { :name => 'EMPIRE_GITHUB_CLIENT_SECRET', :value => ref!(:github_client_secret) },
                 { :name => 'EMPIRE_GITHUB_ORGANIZATION', :value => ref!(:github_organization) },
                 { :name => 'EMPIRE_PORT', :value => '8080' },
                 { :name => 'EMPIRE_ROUTE53_INTERNAL_ZONE_ID', :value => ref!(:internal_domain) },
                 { :name => 'EMPIRE_RUN_LOGS_BACKEND', :value => 'stdout' },
                 { :name => 'EMPIRE_S3_TEMPLATE_BUCKET', :value => ref!(:empire_custom_resources_s3_bucket) },
                 { :name => 'EMPIRE_SNS_TOPIC', :value => ref!(:empire_events_sns_notification_topic) },
                 { :name => 'EMPIRE_SCHEDULER', :value => ref!(:empire_scheduler) },
                 { :name => 'EMPIRE_SERVER_SESSION_EXPIRATION', :value => '24h') },
                 { :name => 'EMPIRE_TOKEN_SECRET', :value => ref!(:empire_token_secret) },
                 { :name => 'EMPIRE_X_SHOW_ATTACHED', :value =>  'false' },
                 { :name => 'LOAD_BALANCER_TYPE', :value => ref!(:load_balancer_type) }
               ]
             }
           ],
           :volume_definitions => [
             { :name => 'dockerSocket', :source_path => '/var/run/docker.sock' },
             { :name => 'dockerCfg', :source_path => '/root/.docker/config.json' }
           ])

  # Empire Minions.  The instances themselves have access to an IAM instance profile and no services are declared.
  dynamic!(:ecs_cluster, 'empire_minion')

  dynamic!(:launch_config_empire,
           'minion',
           :instance_type => 'c4.large',
           :iam_instance_profile => 'EcsinstanceIamInstanceProfile',
           :iam_role => 'EcsinstanceIamRole',
           :create_ebs_volume => true,
           :create_ebs_swap => true,
           :security_groups => lookup.get_security_group_ids(vpc),
           :bootstrap_files => 'empire_minion_files',
           :monitoring => true,
           :cluster => 'EmpireMinionEcsCluster')

  dynamic!(:auto_scaling_group,
           'minion',
           :launch_config => :minion_launch_config,
           :subnets => lookup.get_subnets(vpc),
           :notification_topic => 'EmpireSnsNotificationTopic')
end



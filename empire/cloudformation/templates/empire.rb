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
ENV['empire_token_secret']      ||= 'idontknowjustusewhatevertokenyouwant'
ENV['new_relic_license_key']    ||= 'nope'
ENV['enable_sumologic']         ||= 'true'
ENV['sumologic_access_id']      ||= 'nope'
ENV['sumologic_access_key']     ||= 'nope'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc
certs = lookup.get_ssl_certs

SparkleFormation.new('empire').load(:empire_ami, :ssh_key_pair).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates two auto scaling groups, two ECS clusters, and an ELB. One ASG runs the Empire API, while the other runs Empire Minions.
EOF

  parameters(:empire_version) do
    type 'String'
    default '0.10.0'
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
    default lookup.get_public_subnets(vpc).join(',')
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

  parameters(:empire_run_logs_backend) do
    type 'String'
    default 'cloudwatch'
    allowed_values %w(stdout cloudwatch)
    description 'No clue.  New feature.  Ignore.'
  end

  parameters(:empire_cloudwatch_log_group) do
    type 'String'
    default "#{ENV['org']}-#{ENV['environment']}-empire-run-logs"
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Some kind of cloudwatch log group -- new feature.  Ignore.'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_token_secret) do
    type 'String'
    default SecureRandom.hex
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
    allowed_values certs
    description 'SSL certificate to use with the elastic load balancer'
  end

  parameters(:new_relic_license_key) do
    type 'String'
    default ENV['new_relic_license_key']
    allowed_pattern "[\\x20-\\x7E]*"
    description 'New Relic license key for server monitoring'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:enable_sumologic) do
    type 'String'
    allowed_values %w(true false)
    default ENV['enable_sumologic']
    description 'Deploy the sumologic collector container to all instances'
  end

  parameters(:sumologic_access_id) do
    type 'String'
    default ENV['sumologic_access_id']
    allowed_pattern "[\\x20-\\x7E]*"
    description 'SumoLogic access ID for log collection'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:sumologic_access_key) do
    type 'String'
    default ENV['sumologic_access_key']
    allowed_pattern "[\\x20-\\x7E]*"
    description 'SumoLogic access key for log collection'
    constraint_description 'can only contain ASCII characters'
  end


  # An ELB for Empire Controller instances.  Not managed by Empire, itself.
  dynamic!(:elb, 'empire',
    :listeners => [
      { :instance_port => '8080', :instance_protocol => 'http', :load_balancer_port => '443', :protocol => 'https', :ssl_certificate_id => ref!(:elb_ssl_certificate_id) }
    ],
    :security_groups => lookup.get_security_group_ids(vpc, ENV['controller_public_sg']),
    :subnets => lookup.get_public_subnets(vpc),
    :scheme => 'internet-facing',
    :lb_name => ENV['lb_name'],
    :ssl_certificate_ids => certs
  )

  # A DNS CNAME pointing to the ELB, above.
  dynamic!(:route53_record_set, 'empire_elb', :record => 'empire', :target => :empire_elb, :domain_name => ENV['public_domain'], :attr => 'CanonicalHostedZoneName', :ttl => '60')

  # Empire controllers.
  dynamic!(:iam_ecs_role, 'empire', :policy_statements => [ :empire_service ])

  dynamic!(:launch_config_empire, 'controller', :instance_type => 't2.small', :create_ebs_volumes => true, :security_groups => lookup.get_security_group_ids(vpc, ENV['controller_sg']), :bootstrap_files => 'empire_controller_files', :cluster => 'EmpireControllerEcsCluster')
  dynamic!(:auto_scaling_group, 'controller', :launch_config => :controller_launch_config, :desired_capacity => 2, :max_size => 2, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)

  dynamic!(:ecs_cluster, 'empire_controller')

  dynamic!(:ecs_service,
           'empire_controller',
           :desired_count => 2,
           :ecs_cluster => 'EmpireControllerEcsCluster',
           :load_balancers => [ { :container_name => 'empire_controller', :container_port => '8080', :load_balancer => 'EmpireElb' } ],
           :service_role => 'EmpireIamEcsRole',
           :service_policy => 'EmpireIamEcsPolicy',
           :task_definition => 'EmpireTaskDefinition',
           :auto_scaling_group => 'ControllerAsg')

  # Some notes are in order, here.  EMPIRE_GITHUB_CLIENT_ID and EMPIRE_GITHUB_CLIENT_SECRET need to be
  # OAuth keys that you can use to log into EMPIRE_GITHUB_ORGANIZATION as an OAuth App.
  # See http://empire.readthedocs.org/en/latest/production_best_practices/#securing-the-api
  dynamic!(:ecs_task_definition,
           'empire',
           :container_definitions => [
             {
               :name => 'empire_controller',
               :image => join!('remind101/empire', ref!(:empire_version), {:options => { :delimiter => ':'}}),
               :command => [ 'server', '--automigrate=true' ],
               :memory => 256,
               :port_mappings => [ { :container_port => '8080', :host_port => '8080' } ],
               :mount_points => [
                 { :source_volume => 'dockerSocket', :container_path => '/var/run/docker.sock', :read_only => false},
                 { :source_volume => 'dockerCfg', :container_path => '/root/.dockercfg', :read_only => false}
               ],
               :essential => true,
               :environment => [
                 { :name => 'AWS_REGION', :value => region! },
                 { :name => 'EMPIRE_DATABASE_URL', :value => join!('postgres://', ref!(:empire_database_user), ':', ref!(:empire_database_password), '@empire-rds.', ENV['private_domain'], '/empire') },
                 { :name => 'EMPIRE_GITHUB_CLIENT_ID', :value => ref!(:github_client_id) },
                 { :name => 'EMPIRE_GITHUB_CLIENT_SECRET', :value => ref!(:github_client_secret) },
                 { :name => 'EMPIRE_GITHUB_ORGANIZATION', :value => ref!(:github_organization) },
                 { :name => 'EMPIRE_TOKEN_SECRET', :value => ref!(:empire_token_secret) },
                 { :name => 'EMPIRE_PORT', :value => '8080' },
                 { :name => 'EMPIRE_ECS_CLUSTER', :value => ref!(:empire_minion_ecs_cluster) },
                 { :name => 'EMPIRE_ELB_VPC_ID', :value => vpc },
                 { :name => 'EMPIRE_ELB_SG_PRIVATE', :value => ref!(:empire_elb_sg_private) },
                 { :name => 'EMPIRE_ELB_SG_PUBLIC', :value => ref!(:empire_elb_sg_public) },
                 { :name => 'EMPIRE_ROUTE53_INTERNAL_ZONE_ID', :value => ref!(:internal_domain) },
                 { :name => 'EMPIRE_EC2_SUBNETS_PRIVATE', :value => join!(lookup.get_private_subnet_ids(vpc), {:options => { :delimiter => ','}}) },
                 { :name => 'EMPIRE_EC2_SUBNETS_PUBLIC', :value => join!(lookup.get_public_subnets(vpc), {:options => { :delimiter => ','}}) },
                 { :name => 'EMPIRE_ECS_SERVICE_ROLE', :value => ref!(:empire_iam_ecs_role) },
                 { :name => 'EMPIRE_RUN_LOGS_BACKEND', :value => ref!(:empire_run_logs_backend) },
                 { :name => 'EMPIRE_CLOUDWATCH_LOG_GROUP', :value => ref!(:empire_cloudwatch_log_group) }
               ]
             }
           ],
           :volume_definitions => [
             { :name => 'dockerSocket', :source_path => '/var/run/docker.sock' },
             { :name => 'dockerCfg', :source_path => '/etc/empire/dockercfg' }
           ]
  )

  # Empire Minions.  The instances themselves have access to an IAM instance profile and no services are declared.
  dynamic!(:iam_instance_profile, 'empire', :policy_statements => [ :empire_instance ])

  dynamic!(:ecs_cluster, 'empire_minion')

  dynamic!(:launch_config_empire, 'minion', :instance_type => 'm3.large', :create_ebs_volumes => true, :security_groups => lookup.get_security_group_ids(vpc), :bootstrap_files => 'empire_minion_files', :cluster => 'EmpireMinionEcsCluster')
  dynamic!(:auto_scaling_group, 'minion', :launch_config => :minion_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)

end



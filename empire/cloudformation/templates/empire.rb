require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

ENV['net_type']                 ||= 'Private'
ENV['sg']                       ||= 'private_sg'
ENV['lb_name']                  ||= 'empire'
ENV['volume_count']             ||= '8'
ENV['volume_size']              ||= '250'
ENV['empire_database_user']     ||= 'empire'
ENV['empire_database_password'] ||= 'empirepass'
ENV['empire_token_secret']      ||= 'idontknowjustusewhatevertokenyouwant'

lookup = Indigo::CFN::Lookups.new
vpc = lookup.get_vpc
certs = lookup.get_ssl_certs

SparkleFormation.new('empire').load(:empire_ami, :ssh_key_pair).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates two auto scaling groups and an ELB. One ASG runs the Empire API, while the other runs Empire Minions.
EOF

  parameters(:empire_version) do
    type 'String'
    default 'latest'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Docker tag to specify the version of Empire to run'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_elb_sg_public) do
    type 'String'
    default lookup.get_security_groups(vpc).join(',')
    allowed_pattern "[\\x20-\\x7E]*"
    description 'I have no idea what this is about'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_elb_sg_private) do
    type 'String'
    default lookup.get_security_groups(vpc).join(',')
    allowed_pattern "[\\x20-\\x7E]*"
    description 'I have no idea what this is about'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:empire_private_subnets) do
    type 'String'
    default lookup.get_private_subnets(vpc).join(',')
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

  parameters(:github_client_id) do
    type 'String'
    default ''
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Username for github login'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:github_client_secret) do
    type 'String'
    default ''
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Password for github login'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:github_organization) do
    type 'String'
    default 'indigobio'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Password for github login'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:internal_domain) do
    type 'String'
    default ENV['private_domain']
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Internal domain for Empire'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:elb_ssl_certificate_id) do
    type 'String'
    allowed_values certs
    description 'SSL certificate to use with the elastic load balancer'
  end

  dynamic!(:elb, 'empire',
    :listeners => [
      { :instance_port => '8080', :instance_protocol => 'tcp', :load_balancer_port => '8080', :protocol => 'tcp' }
    ],
    :security_groups => lookup.get_security_groups(vpc),
    :subnets => lookup.get_subnets(vpc),
    :scheme => 'internal',
    :lb_name => ENV['lb_name']
  )

  dynamic!(:route53_record_set, 'empire_elb', :record => "#{ENV['lb_name']}", :target => :empire_elb, :domain_name => ENV['public_domain'], :attr => 'CanonicalHostedZoneName', :ttl => '60')

  dynamic!(:iam_ecs_role, 'empire', :policy_statements => [ :empire_service ])
  dynamic!(:iam_instance_profile, 'empire', :policy_statements => [ :empire_instance ])

  dynamic!(:launch_config_empire, 'controller', :instance_type => 't2.small', :create_ebs_volumes => false, :security_groups => lookup.get_security_groups(vpc), :bootstrap_files => 'empire_controller_files', :cluster => 'EmpireEcsCluster')
  dynamic!(:auto_scaling_group, 'controller', :launch_config => :controller_launch_config, :desired_capacity => 2, :max_size => 2, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)

  dynamic!(:launch_config_empire, 'minion', :instance_type => 'm3.large', :create_ebs_volumes => true, :security_groups => lookup.get_security_groups(vpc), :bootstrap_files => 'empire_minion_files', :cluster => 'EmpireEcsCluster')
  dynamic!(:auto_scaling_group, 'minion', :launch_config => :minion_launch_config, :subnets => lookup.get_subnets(vpc), :notification_topic => lookup.get_notification_topic)

  dynamic!(:ecs_cluster, 'empire')

  # Depends on the auto scaling group
  dynamic!(:ecs_service,
           'empire',
           :desired_count => 2,
           :ecs_cluster => 'EmpireEcsCluster',
           :load_balancers => [ { :container_name => 'empire', :container_port => '8080', :load_balancer => 'EmpireElb' } ],
           :service_role => 'EmpireIamEcsRole',
           :service_policy => 'EmpireIamEcsPolicy',
           :task_definition => 'EmpireTaskDefinition',
           :auto_scaling_group => 'MinionAsg')

  # Jesus, take the wheel.
  dynamic!(:ecs_task_definition,
           'empire',
           :container_definitions => [
             {
               :name => 'empire',
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
                 { :name => 'EMPIRE_DATABASE_URL', :value => join!('postgres://', ref!(:empire_database_user), ':', ref!(:empire_database_password), '@empire-rds.', ref!(:internal_domain), '/empire') },
                 { :name => 'EMPIRE_GITHUB_CLIENT_ID', :value => ref!(:github_client_id) },
                 { :name => 'EMPIRE_GITHUB_CLIENT_SECRET', :value => ref!(:github_client_secret) },
                 { :name => 'EMPIRE_GITHUB_ORGANIZATION', :value => ref!(:github_organization) },
                 { :name => 'EMPIRE_TOKEN_SECRET', :value => ref!(:empire_token_secret) },
                 { :name => 'EMPIRE_PORT', :value => '8080' },
                 { :name => 'EMPIRE_ECS_CLUSTER', :value => ref!(:empire_ecs_cluster) },
                 { :name => 'EMPIRE_ELB_VPC_ID', :value => vpc },
                 { :name => 'EMPIRE_ELB_SG_PRIVATE', :value => ref!(:empire_elb_sg_private) },
                 { :name => 'EMPIRE_ELB_SG_PUBLIC', :value => ref!(:empire_elb_sg_public) },
                 { :name => 'EMPIRE_ROUTE53_INTERNAL_ZONE_ID', :value => ref!(:internal_domain) },
                 { :name => 'EMPIRE_EC2_SUBNETS_PRIVATE', :value => join!(lookup.get_private_subnets(vpc), {:options => { :delimiter => ','}}) },
                 { :name => 'EMPIRE_EC2_SUBNETS_PUBLIC', :value => join!(lookup.get_public_subnets(vpc), {:options => { :delimiter => ','}}) },
                 { :name => 'EMPIRE_ECS_SERVICE_ROLE', :value => ref!(:empire_iam_ecs_role) }
               ]
             }
           ],
           :volume_definitions => [
             { :name => 'dockerSocket', :source_path => '/var/run/docker.sock' },
             { :name => 'dockerCfg', :source_path => '/etc/empire/dockercfg' }
           ]
  )
end



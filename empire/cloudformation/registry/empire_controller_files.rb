SfnRegistry.register(:empire_controller_files) do
  metadata('AWS::CloudFormation::Init') do
    _camel_keys_set(:auto_disable)
    config do
      files('/etc/empire/seed') do
        content join!(
          "EMPIRE_HOSTGROUP=controller\n",
          "EMPIRE_DATABASE_USER=", ref!(:empire_database_user), "\n",
          "EMPIRE_DATABASE_PASSWORD=", ref!(:empire_database_password), "\n",
          "EMPIRE_DATABASE_HOST=empire-rds.", ENV['private_domain'], "\n",
          "EMPIRE_GITHUB_CLIENT_ID=", ref!(:github_client_id), "\n",
          "EMPIRE_GITHUB_CLIENT_SECRET=", ref!(:github_client_secret), "\n",
          "EMPIRE_GITHUB_ORGANIZATION=", ref!(:github_organization), "\n",
          "EMPIRE_TOKEN_SECRET=", ref!(:empire_token_secret), "\n",
          "EMPIRE_ELB_SG_PRIVATE=", ref!(:empire_elb_sg_private), "\n",
          "EMPIRE_ELB_SG_PUBLIC=", ref!(:empire_elb_sg_public), "\n",
          "EMPIRE_EC2_SUBNETS_PRIVATE=", ref!(:empire_private_subnets), "\n",
          "EMPIRE_EC2_SUBNETS_PUBLIC=", ref!(:empire_public_subnets), "\n",
          "EMPIRE_ECS_SERVICE_ROLE=", ref!(:empire_iam_ecs_role), "\n",
          "EMPIRE_ROUTE53_INTERNAL_ZONE_ID=", ref!(:internal_domain), "\n",
          "EMPIRE_AWS_DEBUG=false\n",
          "EMPIRE_ECS_CLUSTER=", ref!(:empire_minion_ecs_cluster), "\n",
          "ECS_AGENT_VERSION=", ref!(:ecs_agent_version), "\n",
          "ECS_CLUSTER=", ref!(:empire_controller_ecs_cluster), "\n",
          "DOCKER_USER=", ref!(:docker_user), "\n",
          "DOCKER_PASS=", ref!(:docker_pass), "\n",
          "DOCKER_EMAIL=", ref!(:docker_email), "\n",
          "DOCKER_REGISTRY=", ref!(:docker_registry), "\n",
          "DOCKER_VERSION=", ref!(:docker_version), "\n",
          "NEW_RELIC_LICENSE_KEY=", ENV['new_relic_license_key'], "\n",
          "NEW_RELIC_SERVER_LABELS=", ref!(:new_relic_server_labels), "\n",
          "SUMOLOGIC_ACCESS_ID=", ENV['sumologic_access_id'], "\n",
          "SUMOLOGIC_ACCESS_KEY=", ENV['sumologic_access_key'], "\n",
          "ENABLE_SUMOLOGIC=", ref!(:enable_sumologic), "\n",
          "EMPIRE_ENVIRONMENT=", ENV['environment'], "\n",
          "DD_AGENT_VERSION=", ref!(:dd_agent_version), "\n",
          "DD_API_KEY=", ENV['dd_api_key'], "\n",
          "ENABLE_DATADOG=", ref!(:enable_datadog), "\n"
        )
        mode '000644'
        owner 'root'
        group 'root'
      end
    end
  end
end

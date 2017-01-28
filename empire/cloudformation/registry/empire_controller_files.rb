SfnRegistry.register(:empire_controller_files) do
  metadata('AWS::CloudFormation::Init') do
    _camel_keys_set(:auto_disable)
    config do
      files('/etc/empire/seed') do
        content join!(
          "EMPIRE_HOSTGROUP=controller\n",
          "ECS_AGENT_VERSION=", ref!(:ecs_agent_version), "\n",
          "ECS_CLUSTER=", ref!(:empire_controller_ecs_cluster), "\n",
          "DOCKER_USER=", ref!(:docker_user), "\n",
          "DOCKER_PASS=", ref!(:docker_pass), "\n",
          "DOCKER_EMAIL=", ref!(:docker_email), "\n",
          "DOCKER_REGISTRY=", ref!(:docker_registry), "\n",
          "DOCKER_VERSION=", ref!(:docker_version), "\n",
          "NEW_RELIC_LICENSE_KEY=", ref!(:new_relic_license_key), "\n",
          "NEW_RELIC_SERVER_LABELS=", ref!(:new_relic_server_labels), "\n",
          "SUMOLOGIC_ACCESS_ID=", ref!(:sumologic_access_id), "\n",
          "SUMOLOGIC_ACCESS_KEY=", ref!(:sumologic_access_key), "\n",
          "ENABLE_SUMOLOGIC=", ref!(:enable_sumologic), "\n"
        )
        mode '000644'
        owner 'root'
        group 'root'
      end
    end
  end
end

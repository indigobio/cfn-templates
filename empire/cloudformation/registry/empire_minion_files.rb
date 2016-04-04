SfnRegistry.register(:empire_minion_files) do
  metadata('AWS::CloudFormation::Init') do
    _camel_keys_set(:auto_disable)
    config do
      files('/etc/empire/seed') do
        content join!(
                  "EMPIRE_HOSTGROUP=minion\n",
                  "ECS_CLUSTER=", ref!(:empire_minion_ecs_cluster), "\n",
                  "DOCKER_USER=", ref!(:docker_user), "\n",
                  "DOCKER_PASS=", ref!(:docker_pass), "\n",
                  "DOCKER_EMAIL=", ref!(:docker_email), "\n",
                  "DOCKER_REGISTRY=", ref!(:docker_registry), "\n",
                  "NEW_RELIC_LICENSE_KEY=", ref!(:new_relic_license_key), "\n",
                  "SUMOLOGIC_ACCESS_ID=", ref!(:sumologic_access_id), "\n",
                  "SUMOLOGIC_ACCESS_KEY=", ref!(:sumologic_access_key), "\n",
                  "SUMOLOGIC_COLLECTOR_NAME=", ref!(:sumologic_collector_name), "\n",
                  "ENABLE_SUMOLOGIC=", ref!(:enable_sumologic), "\n",
                  "EMPIRE_ENVIRONMENT=", ENV['environment'], "\n"
                )
        mode '000644'
        owner 'root'
        group 'root'
      end
    end
  end
end

SfnRegistry.register(:jenkins_slave_bootstrap_files) do
  metadata('AWS::CloudFormation::Init') do
    _camel_keys_set(:auto_disable)
    config do
      files('/etc/jenkins-slave/seed') do
        content join!(
                  "ECS_CLUSTER=", ref!(:jenkinsslaves_ecs_cluster), "\n",
                  "ECS_AGENT_VERSION=", ref!(:ecs_agent_version), "\n",
                  "DOCKER_USER=", ref!(:docker_user), "\n",
                  "DOCKER_PASS=", ref!(:docker_pass), "\n",
                  "DOCKER_EMAIL=", ref!(:docker_email), "\n",
                  "DOCKER_REGISTRY=", ref!(:docker_registry), "\n",
                  "DOCKER_VERSION=", ref!(:docker_version), "\n"
                )
        mode '000644'
        owner 'root'
        group 'root'
      end
    end
  end
end

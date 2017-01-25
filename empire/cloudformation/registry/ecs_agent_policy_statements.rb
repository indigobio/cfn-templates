SfnRegistry.register(:ecs_agent_policy_statements) do
  {
    'Action' => %w(ecs:DeregisterContainerInstance,
                   ecs:DiscoverPollEndpoint,
                   ecs:Poll,
                   ecs:RegisterContainerInstance,
                   ecs:StartTelemetrySession,
                   ecs:Submit*,
                   ecr:GetAuthorizationToken,
                   ecr:BatchChecklayerAvailability,
                   ecr:GetDownloadUrlForLayer,
                   ecr:BatchGetImage
                  ),
    'Resource' => %w( * ),
    'Effect' => 'Allow'
  }
end
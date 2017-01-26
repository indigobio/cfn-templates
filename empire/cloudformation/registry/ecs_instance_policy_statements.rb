SfnRegistry.register(:ecs_instance_policy_statements) do
  [
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

    },
    {
      'Action' => %w(cloudformation:DescribeStackResource,
                   cloudformation:SignalResource
                  ),
      'Resource' => %w( * ),
      'Effect' => 'Allow'
    },
    {
      'Action' => %w( autoscaling:SetInstanceHealth ),
      'Resource' => '*',
      'Effect' => 'Allow'
    }
  ]
end
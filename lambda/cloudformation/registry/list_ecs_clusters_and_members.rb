SfnRegistry.register(:list_ecs_clusters_and_members) do
    { 'Action'   => %w( ecs:ListClusters
                        ecs:ListContainerInstances ),
      'Resource' => '*',
      'Effect'   => 'Allow'
    }
end
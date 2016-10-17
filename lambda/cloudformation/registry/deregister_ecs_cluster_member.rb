SfnRegistry.register(:deregister_ecs_cluster_member) do
  { 'Action'   => %w( ecs:DeregisterContainerInstance
                      ecs:DescribeClusters
                      ecs:DescribeContainerInstances ),
    'Resource' => [
                    join!(['arn','aws','ecs',region!,account_id!,'cluster/*'], { :options => { :delimiter => ':'}}),
                    join!(['arn','aws','ecs',region!,account_id!,'container-instance/*'], { :options => { :delimiter => ':'}})
                  ],
    'Effect'   => 'Allow'
  }
end
SparkleFormation.dynamic(:ecs_service) do |_name, _config = {}|

  # {
  #   "Type" : "AWS::ECS::Service",
  #   "Properties" : {
  #     "Cluster" : String,
  #     "DesiredCount" : Integer,
  #     "LoadBalancers" : [ Load Balancer Objects, ... ],
  #     "Role" : String,
  #     "TaskDefinition" : String
  #   }
  # }

  # "LoadBalancers": {
  #   "ContainerName" : String,
  #  "ContainerPort" : Integer,
  #  "LoadBalancerName" : String
  # }

  resources("#{_name}_ecs_service".to_sym) do
    depends_on _array(
      _config[:ecs_cluster],
      _config[:service_role],
      _config[:service_policy],
      _config[:auto_scaling_group]
    )
    type 'AWS::ECS::Service'
    properties do
      cluster ref!("#{_name}_ecs_cluster".to_sym)
      desired_count _config[:desired_count]
      load_balancers _array(
        *_config[:load_balancers].map { |lb| {
          'ContainerName' => lb[:container_name],
          'ContainerPort' => lb[:container_port],
          'LoadBalancerName' => ref!(lb[:load_balancer])
        }
      })
      role ref!(_config[:service_role])
      task_definition ref!(_config[:task_definition])
    end
  end
end
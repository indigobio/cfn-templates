SparkleFormation.dynamic(:ecs_cluster) do |_name|
  resources("#{_name}_ecs_cluster".to_sym) do
    type 'AWS::ECS::Cluster'
  end
end
SparkleFormation.dynamic(:ecs_task_definition) do |_name, _config = {}|

  # {
  #   "Type" : "AWS::ECS::TaskDefinition",
  #   "Properties" : {
  #     "ContainerDefinitions" : [ Container Definition, ... ],
  #     "Volumes" : [ Volume Definition, ... ]
  #   }
  # }

  # See registry/ecs_container_definition.rb and
  # registry/ecs_volume_definition for more details

  resources("#{_name}_task_definition".to_sym) do
    type 'AWS::ECS::TaskDefinition'
    properties do
      if _config.has_key?(:task_role)
        task_role_arn attr!(_config[:task_role], :arn)
      end
      container_definitions _array(
        *_config[:container_definitions].map { |d| registry!(:ecs_container_definition, d) }
      )
      volumes _array(
        *_config[:volume_definitions].map { |d| registry!(:ecs_volume_definition, d) }
      )
    end
  end

end
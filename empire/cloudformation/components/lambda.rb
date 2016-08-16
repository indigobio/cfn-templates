SparkleFormation.build do

# {
#   "Type" : "AWS::Lambda::Function",
#   "Properties" : {
#     "Code" : Code,
#     "Description" : String,
#     "Handler" : String,
#     "MemorySize" : Integer,
#     "Role" : String,
#     "Runtime" : String,
#     "Timeout" : Integer
#   }
# }

  resources(:deregister_ecs_instances_handler) do
    type 'AWS::Lambda::Function'
    depends_on _array(
      'DeregisterEcsInstancesPolicy',
      'DeregisterEcsInstancesRole'
    )
    properties do
      code do
        registry!(:deregister_ecs_instances_py)
      end
      description 'ECS Instance Deregistration Handler'
      handler 'lambda_function.lambda_handler'
      memory_size '128'
      role attr!(:deregister_ecs_instances_role, :arn)
      runtime 'python2.7'
      timeout '30'
    end
  end
end
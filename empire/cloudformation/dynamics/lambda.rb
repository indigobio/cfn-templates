SparkleFormation.dynamic(:lambda) do |_name, _config|

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

# {
#   "Type": "AWS::Lambda::Permission",
#   "Properties": {
#     "Action": "lambda:InvokeFunction",
#     "Principal": "sns.amazonaws.com",
#     "SourceArn": { "Ref": "Topic" },
#     "FunctionName": {
#       "Fn::GetAtt": [ "Lambda", "Arn" ]
#     }
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
      handler 'index.lambda_handler'
      memory_size '128'
      role attr!(:deregister_ecs_instances_role, :arn)
      runtime 'python2.7'
      timeout '30'
    end
  end

  resources(:deregister_ecs_instances_permission) do
    type 'AWS::Lambda::Permission'
    properties do
      action 'lambda:InvokeFunction'
      principal 'sns.amazonaws.com'
      source_arn ref!(_config[:sns_topic])
      function_name attr!(:deregister_ecs_instances_handler, :arn)
    end
  end

  resources(:deregister_ecs_instances_role) do
    type 'AWS::IAM::Role'
    properties do
      assume_role_policy_document do
        version '2012-10-17'
        statement _array(
                    -> {
                      effect 'Allow'
                      principal do
                        service _array( "lambda.amazonaws.com" )
                      end
                      action _array( "sts:AssumeRole" )
                    }
                  )
      end
      path '/'
    end
  end

  resources(:deregister_ecs_instances_policy) do
    type 'AWS::IAM::Policy'
    depends_on "DeregisterEcsInstancesRole"
    properties do
      policy_name 'CreateLogsAndDeregisterECSInstances'
      policy_document do
        version '2012-10-17'
        statement _array(
                    { 'Action' => %w(logs:CreateLogGroup
                           logs:CreateLogStream
                           logs:PutLogEvents
                          ),
                      'Resource' => 'arn:aws:logs:*:*:*',
                      'Effect' => 'Allow'
                    },
                    {
                      'Action' => %w(
                           ecs:DeregisterContainerInstance
                           ecs:DescribeClusters
                           ecs:DescribeContainerInstances
                          ),
                      'Resource' => %w(
                             arn:aws:ecs:*:*:cluster/*
                             arn:aws:ecs:*:*:container-instance/*
                          ),
                      'Effect' => 'Allow'
                    },
                    {
                      'Action' => %w(ecs:ListClusters ecs:ListContainerInstances),
                      'Resource' => '*',
                      'Effect' => 'Allow'
                    }
                  )
      end
      roles _array( ref!(:deregister_ecs_instances_role) )
    end
  end
end
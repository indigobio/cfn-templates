SparkleFormation.build do
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
                           ecs:ListClusters
                           ecs:ListContainerInstances
                          ),
            'Resource' => %w(
                             arn:aws:ecs:*:*:cluster/*
                             arn:aws:ecs:*:*:container-instance/*
                          ),
            'Effect' => 'Allow'
          }
        )
      end
      roles _array( ref!(:deregister_ecs_instances_role) )
    end
  end
end

SfnRegistry.register(:empire_task_definition_policy_statements) do |_config = {}|
  [
    {
      'Action' => %w( iam:PassRole ),
      'Resource' => '*',
      'Effect' => 'Allow'
    },
    {
      'Action' => %w(
        lambda:CreateFunction
        lambda:DeleteFunction
        lambda:UpdateFunctionCode
        lambda:GetFunctionConfiguration
        lambda:AddPermission
        lambda:RemovePermission
      ),
      'Resource' => '*',
      'Effect' => 'Allow'
    },
    {
      'Action' => %w(
        events:PutRule
        events:DeleteRule
        events:DescribeRule
        events:EnableRule
        events:DisableRule
        events:PutTargets
        events:RemoveTargets
      ),
      'Resource' => '*',
      'Effect' => 'Allow'
    },
    {
      'Action' => %w(
        sqs:ReceiveMessage
        sqs:DeleteMessage
        sqs:ChangeMessageVisibility
      ),
      'Resource' => attr!(_config[:custom_resources_queue], :arn),
      'Effect' => 'Allow'
    },
    {
      'Action' => %w(
        sns:Publish
      ),
      'Resource' => ref!(_config[:custom_resources_topic]),
      'Effect' => 'Allow'
    },
    {
      'Action' => %w(
        sns:Publish
      ),
      'Resource' => ref!(_config[:events_topic]),
      'Effect' => 'Allow'
    },
    {
      'Action' => %w(
        s3:PutObject
        s3:PutObjectAcl
        s3:PutObjectVersionAcl
        s3:Get*

      ),
      'Resource' => join!('arn:aws:s3:::', ref!(_config[:custom_resources_bucket]), '/*'),
      'Effect' => 'Allow'
    },
    {
      'Action' => %w(
        cloudformation:CreateStack
        cloudformation:UpdateStack
        cloudformation:DeleteStack
        cloudformation:ListStackResources
        cloudformation:DescribeStackResource
        cloudformation:DescribeStacks
        cloudformation:ValidateTemplate
      ),
      'Resource' => '*',
      'Effect' => 'Allow'
    },
    {
      'Action' => %w(
        ecs:CreateService
        ecs:DeleteService
        ecs:DeregisterTaskDefinition
        ecs:Describe*
        ecs:List*
        ecs:RegisterTaskDefinition
        ecs:RunTask
        ecs:StartTask
        ecs:StopTask
        ecs:SubmitTaskStateChange
        ecs:UpdateService
      ),
      'Resource' => '*',
      'Effect' => 'Allow'
    },
    {
      'Action' => %w( elasticloadbalancing:* ),
      'Resource' => '*',
      'Effect' => 'Allow'
    },
    {
      'Action' => %w(
        ecr:GetAuthorizationToken
        ecr:BatchCheckLayerAvailability
        ecr:GetDownloadUrlForLayer
        ecr:BatchGetImage
      ),
      'Resource' => '*',
      'Effect' => 'Allow'
    },
    {
      'Action' => %w(
        ec2:DescribeSubnets
        ec2:DescribeSecurityGroups
      ),
      'Resource' => '*',
      'Effect' => 'Allow'
    },
    {
      'Action' => %w(
        route53:ListHostedZonesByName
        route53:ChangeResourceRecordSets
        route53:ListResourceRecordSets
        route53:ListHostedZones
        route53:GetHostedZone
      ),
      'Resource' => join!('arn:aws:route53:::hostedzone/', _config[:internal_domain]),
      'Effect' => 'Allow'
    },
    {
      'Action' => %w( route53:GetChange* ),
      'Resource' => '*',
      'Effect' => 'Allow'
    }
  ]
end
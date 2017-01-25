SfnRegistry.register(:empire_service_role_policy_statements) do |_config = {}|
  [
    {
      'Action' => %w(
        ec2:Describe*
        elasticloadbalancing:*
        ecs:*
        iam:ListInstanceProfiles
        iam:ListRoles
        iam:passRole
        route53:*
      ),
      'Effect' => 'Allow',
      'Resource' => '*'
    },
    {
      'Action' => %w(
        lambda:InvokeFunction
      ),
      'Effect' => 'Allow',
      'Resource' => '*'
    },
    {
      'Action' => %w(
            ecs:RunTask
          ),
      'Condition' => {
        'ArnEquals' => {
          'ecs:cluster' => join!('arn:aws:ecs:', region!, ':', account_id!, ':cluster/', ref!(_config[:cluster]))
        }
      },
      'Effect' => 'Allow',
      'Resource' => '*'
    }
  ]
end


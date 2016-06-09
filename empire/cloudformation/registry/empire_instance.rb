SfnRegistry.register(:empire_instance) do
  # Note the capitals
  { 'Action' => %w(ec2:Describe*
                   elasticloadbalancing:*
                   ecs:*
                   iam:ListInstanceProfiles
                   iam:ListRoles
                   iam:PassRole
                   route53:*
                   logs:CreateLogStream
                   logs:PutLogEvents
                  ),
    'Resource' => %w( * ),
    'Effect' => 'Allow'
  }
end


SfnRegistry.register(:jenkins_slave_policy_statements) do
  # Note the capitals
  { 'Action' => %w(ec2:Describe*
                   ecs:*
                   iam:ListInstanceProfiles
                   iam:ListRoles
                   iam:PassRole
                  ),
    'Resource' => %w( * ),
    'Effect' => 'Allow'
  }
end


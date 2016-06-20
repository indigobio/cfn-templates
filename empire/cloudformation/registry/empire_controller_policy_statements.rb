SfnRegistry.register(:empire_controller_policy_statements) do
  # Note the capitals
  { 'Action' => %w(elasticloadbalancing:*
                   ec2:Describe*
                   ecs:*
                   iam:ListInstanceProfiles
                   iam:ListRoles
                   iam:PassRole
                   iam:UploadServerCertificate
                   iam:DeleteServerCertificate
                   route53:ChangeResourceRecordSets
                   route53:ChangeTagsForResource
                   route53:Get*
                   route53:List*
                  ),
    'Resource' => %w( * ),
    'Effect' => 'Allow'
  }
end


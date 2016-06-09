SfnRegistry.register(:empire_service) do
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
                   logs:CreateLogStream
                   logs:PutLogEvents
                  ),
    'Resource' => %w( * ),
    'Effect' => 'Allow'
  }
end


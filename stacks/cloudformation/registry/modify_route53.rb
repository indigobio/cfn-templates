SparkleFormation::Registry.register(:modify_route53) do
  # Note the capitals
  { 'Action' => %w(route53:ChangeResourceRecordSets
                   route53:ChangeTagsForResource
                   route53:Get*
                   route53:ListH*),
    'Resource' => %w( * ),
    'Effect' => 'Allow'
  }
end


SfnRegistry.register(:describe_rds_db_instances) do
  { 'Action' => %w(rds:DescribeDBInstances),
    'Resource' => %w( arn:aws:rds:* ),
    'Effect' => 'Allow'
  }
end
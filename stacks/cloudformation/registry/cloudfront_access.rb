SfnRegistry.register(:cloudfront_access) do
  # Note the capitals
  { 'Action' => %w( cloudfront:Get* cloudfront:List* ),
    'Resource' => '*',
    'Effect' => 'Allow'
  }
end


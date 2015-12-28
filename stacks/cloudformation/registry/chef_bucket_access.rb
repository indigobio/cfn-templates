SfnRegistry.register(:chef_bucket_access) do
  # Note the capitals
  { 'Action' => %w( s3:GetObject ),
    'Resource' => _array(
      join!(
        'arn:aws:s3:::',
        ref!(:chef_validator_key_bucket),
        '/*'
      )
    ),
    'Effect' => 'Allow'
  }
end


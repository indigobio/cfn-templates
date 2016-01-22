SfnRegistry.register(:assets_bucket_access) do |_config = {}|
  # Note the capitals
  { 'Action' => %w( s3:* ),
    'Resource' => _array(
      join!(
        'arn:aws:s3:::',
        ref!(_config[:bucket]),
        '/*'
      ),
      join!(
        'arn:aws:s3:::',
        ref!(_config[:bucket])
      )
    ),
    'Effect' => 'Allow'
  }
end


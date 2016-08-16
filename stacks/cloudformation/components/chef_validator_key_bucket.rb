SparkleFormation.build do
  parameters(:chef_validator_key_bucket) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default "#{ENV['org']}-chef-#{ENV['AWS_DEFAULT_REGION']}"
    description 'An S3 bucket that contains the Chef validator private key.'
    constraint_description 'can only contain ASCII characters'
  end
end
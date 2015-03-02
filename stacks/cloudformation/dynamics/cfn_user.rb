SparkleFormation.dynamic(:cfn_user) do |_name, _config = {}|
  set!('AWSTemplateFormatVersion', '2010-09-09')

  # TODO: kill this
  parameters(:chef_validator_key_bucket) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default "#{ENV['org']}-chef-#{ENV['region']}"
    description 'An S3 bucket that contains the Chef validator private key.'
    constraint_description 'can only contain ASCII characters'
  end

  resources(:cfn_user) do
    type 'AWS::IAM::User'
    properties do
      path '/'
      policies _array(
        -> {
          policy_name 'cfn_access'
          policy_document do
            version '2012-10-17'
            statement _array(
              -> {
                effect 'Allow'
                action %w(cloudformation:DescribeStackResource cloudformation:SignalResource)
                resource '*'
              }
            )
          end
        }
      )
      groups _array(
        ref!(_config[:iam_group])
      )
    end
  end

  resources(:cfn_keys) do
    type 'AWS::IAM::AccessKey'
    properties do
      user_name ref!(:cfn_user)
    end
  end
end

SparkleFormation.dynamic(:iam_instance_profile) do |_name, _config = {}|

  _config[:policy_statements] ||= []

  parameters(:chef_validator_key_bucket) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default "#{ENV['org']}-chef-#{ENV['region']}"
    description 'An S3 bucket that contains the Chef validator private key.'
    constraint_description 'can only contain ASCII characters'
  end

  resources(:iam_instance_profile) do
    depends_on 'IamInstancePolicy'
    type 'AWS::IAM::InstanceProfile'
    properties do
      path '/'
      roles _array(
        ref!(:iam_instance_role)
      )
    end
  end

  resources(:iam_instance_role) do
    type 'AWS::IAM::Role'
    properties do
      assume_role_policy_document do
        version '2012-10-17'
        statement _array(
          -> {
            effect 'Allow'
            principal do
              service _array( "ec2.amazonaws.com" )
            end
            action _array( "sts:AssumeRole" )
          }
        )
      end
      path '/'
    end
  end

  resources(:iam_instance_policy) do
    depends_on 'IamInstanceRole'
    type 'AWS::IAM::Policy'
    properties do
      policy_name 'blah'
      policy_document do
        version '2012-10-17'
        statement _array(
          *_config[:policy_statements].map { |s| registry!(s.to_sym) },
          -> {
            action %w(s3:GetObject)
            resource _array(
              join!(
                'arn:aws:s3:::',
                ref!(:chef_validator_key_bucket),
                '/*'
              )
            )
            effect 'Allow'
          },
          -> {
            action %w(cloudformation:DescribeStackResource cloudformation:SignalResource)
            resource '*'
            effect 'Allow'
          }
        )
      end
      roles _array( ref!(:iam_instance_role) )
    end
  end
end
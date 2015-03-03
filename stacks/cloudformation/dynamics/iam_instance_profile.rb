SparkleFormation.dynamic(:iam_instance_profile) do |_name, _config = {}|

  _config[:policy_statements] ||= []

  resources("#{_name}_iam_instance_profile".to_sym) do
    depends_on "#{_name.capitalize}IamInstancePolicy"
    type 'AWS::IAM::InstanceProfile'
    properties do
      path '/'
      roles _array(
        ref!("#{_name}_iam_instance_role".to_sym)
      )
    end
  end

  resources("#{_name}_iam_instance_role".to_sym) do
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

  resources("#{_name}_iam_instance_policy".to_sym) do
    depends_on "#{_name.capitalize}IamInstancePolicy"
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
      roles _array( ref!("#{_name}_iam_instance_role".to_sym) )
    end
  end
end
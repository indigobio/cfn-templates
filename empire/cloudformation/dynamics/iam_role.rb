SparkleFormation.dynamic(:iam_role) do |_name, _config = {}|

  resources("#{_name}_iam_role".to_sym) do
    type 'AWS::IAM::Role'
    properties do
      assume_role_policy_document do
        version '2012-10-17'
        statement _array(
          -> {
            effect 'Allow'
            principal do
              service _config.fetch(:services, [ 'ec2.amazonaws.com' ])
            end
            action _array( "sts:AssumeRole" )
          }
        )
      end
      path '/'
    end
  end
end
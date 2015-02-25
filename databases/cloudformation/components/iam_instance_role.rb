SparkleFormation.build do
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
end

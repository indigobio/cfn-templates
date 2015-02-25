SparkleFormation.build do

  resources(:nat_instance_iam_profile) do
    depends_on 'NatInstanceIamPolicies'
    type 'AWS::IAM::InstanceProfile'
    properties do
      path '/'
      roles _array(
        ref!(:nat_instance_iam_role)
      )
    end
  end

  resources(:nat_instance_iam_role) do
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

  resources(:nat_instance_iam_policies) do
    depends_on 'NatInstanceIamRole'
    type 'AWS::IAM::Policy'
    properties do
      policy_name 'allow-nat-instance-to-modify-private-subnet-route-tables'
      policy_document do
        version '2012-10-17'
        statement _array(
          -> {
            action _array(
              'ec2:DescribeInstances',
              'ec2:ModifyInstanceAttribute',
              'ec2:DescribeSubnets',
              'ec2:DescribeRouteTables',
              'ec2:CreateRoute',
              'ec2:ReplaceRoute'
            )
            resource _array( '*' )
            effect 'Allow'
          }
        )
      end
      roles _array( ref!(:nat_instance_iam_role) )
    end
  end
end
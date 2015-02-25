SparkleFormation.build do
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
end
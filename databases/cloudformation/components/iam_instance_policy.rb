SparkleFormation.build do
  resources(:iam_instance_policy) do
    depends_on 'IamInstanceRole'
    type 'AWS::IAM::Policy'
    properties do
      policy_name 'allow-ec2-instance-to-create-snapshots-and-tags'
      policy_document do
        version '2012-10-17'
        statement _array(
          -> {
            action _array(
              'ec2:CreateSnapshot',
              'ec2:DeleteSnapshot',
              'ec2:DescribeSnapshots',
              'ec2:AttachVolume',
              'ec2:CreateVolume',
              'ec2:ModifyVolumeAttribute',
              'ec2:DescribeVolumeAttribute',
              'ec2:DescribeVolumeStatus',
              'ec2:DescribeVolumes',
              'ec2:DetachVolume',
              'ec2:EnableVolumeIO',
              'ec2:*Tags',
              'ec2:DescribeInstances'
            )
            resource _array( '*' )
            effect 'Allow'
          }
        )
      end
      roles _array( ref!(:iam_instance_role) )
    end
  end
end
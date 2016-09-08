SfnRegistry.register(:create_snapshots) do
  # Note the capitals
  { 'Action' => %w(ec2:CreateSnapshot
                   ec2:DeleteSnapshot
                   ec2:DescribeSnapshots
                   ec2:ModifySnapshotAttribute
                   ec2:AttachVolume
                   ec2:CreateVolume
                   ec2:ModifyVolumeAttribute
                   ec2:DescribeVolumeAttribute
                   ec2:DescribeVolumeStatus
                   ec2:DescribeVolumes
                   ec2:DetachVolume
                   ec2:EnableVolumeIO
                   ec2:*Tags
                   ec2:DescribeInstances
                  ),
    'Resource' => %w( * ),
    'Effect' => 'Allow'
  }
end


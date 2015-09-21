SfnRegistry.register(:modify_eips) do
  # Note the capitals
  { 'Action' => %w(ec2:AssociateAddress
                   ec2:DescribeAddresses
                   ec2:DisassociateAddress
                   ec2:*Tags
                   ec2:DescribeInstances
                  ),
    'Resource' => %w( * ),
    'Effect' => 'Allow'
  }
end


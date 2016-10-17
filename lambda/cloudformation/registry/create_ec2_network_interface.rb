SfnRegistry.register(:create_ec2_network_interface) do
  { 'Action' => %w(ec2:CreateNetworkInterface),
    'Resource' => %w( * ),
    'Effect' => 'Allow'
  }
end
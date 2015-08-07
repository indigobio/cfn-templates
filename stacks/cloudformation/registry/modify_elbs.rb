SparkleFormation::Registry.register(:modify_elbs) do
  # Note the capitals
  { 'Action' => %w(elasticloadbalancing:Describe*
                   elasticloadbalancing:DeregisterInstancesFromLoadBalancer
                   elasticloadbalancing:RegisterInstancesWithLoadBalancer
                  ),
    'Resource' => %w( * ),
    'Effect' => 'Allow'
  }
end


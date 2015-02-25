SparkleFormation::Registry.register(:inbound_icmp) do
  icmp_rules = [
    { 'cidr_ip' => '0.0.0.0/0', 'ip_protocol' => 'icmp', 'from_port' => '0', 'to_port' => '-1' },
    { 'cidr_ip' => '0.0.0.0/0', 'ip_protocol' => 'icmp', 'from_port' => '3', 'to_port' => '-1' },
    { 'cidr_ip' => '0.0.0.0/0', 'ip_protocol' => 'icmp', 'from_port' => '5', 'to_port' => '-1' },
    { 'cidr_ip' => '0.0.0.0/0', 'ip_protocol' => 'icmp', 'from_port' => '11', 'to_port' => '-1' },
    { 'cidr_ip' => '0.0.0.0/0', 'ip_protocol' => 'icmp', 'from_port' => '12', 'to_port' => '-1' }
  ]
end
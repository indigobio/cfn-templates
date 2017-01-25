SparkleFormation.build do
  cidrs = { 'us-east-1'    => [ { 'cidr' => '172.19.0.0/16', 'network' => '19', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.20.0.0/16', 'network' => '20', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.21.0.0/16', 'network' => '21', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.23.0.0/16', 'network' => '23', 'azs' => ['a', 'c', 'd', 'e', 'b'] } ],

            'us-east-2'    => [ { 'cidr' => '172.28.0.0/16', 'network' => '24', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.29.0.0/16', 'network' => '25', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.30.0.0/16', 'network' => '26', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.31.0.0/16', 'network' => '27', 'azs' => ['a', 'c', 'd', 'e', 'b'] } ],

            'us-west-2'    => [ { 'cidr' => '172.24.0.0/16', 'network' => '24', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.25.0.0/16', 'network' => '25', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.26.0.0/16', 'network' => '26', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.27.0.0/16', 'network' => '27', 'azs' => ['a', 'c', 'd', 'e', 'b'] } ],

            'us-west-1'    => [ { 'cidr' => '172.28.0.0/16', 'network' => '28', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.29.0.0/16', 'network' => '29', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.30.0.0/16', 'network' => '30', 'azs' => ['a', 'c', 'd', 'e', 'b'] },
                                { 'cidr' => '172.31.0.0/16', 'network' => '31', 'azs' => ['a', 'c', 'd', 'e', 'b'] } ]
          }

  parameters(:vpc_cidr_block) do
    description 'VPC CIDR block'
    type 'String'
    allowed_values cidrs[ENV['AWS_DEFAULT_REGION']].map { |cidr| cidr['network'] }
    default cidrs[ENV['AWS_DEFAULT_REGION']].first['network']
    description 'The /16 network address of the VPC.  The address will be 172.X.0.0/16.'
  end

  mappings(:cidr_to_region) do
    cidrs.each do |region, data|
      map = Hash.new
      data.each do |e|
        map[e['network']] = e['cidr']
      end
      data.each do |cidr|
        set!("#{region}".disable_camel!, map)
      end
    end
  end

  mappings(:subnets_to_az) do
    cidrs[ENV['AWS_DEFAULT_REGION']].each do |e|
      map = Hash.new
      e['azs'].each_with_index do |az, i|
        map["#{ENV['AWS_DEFAULT_REGION']}#{az}Public".gsub('-','_')] = "172.#{e['network']}.#{i * 16}.0/20"
        map["#{ENV['AWS_DEFAULT_REGION']}#{az}Private".gsub('-','_')] = "172.#{e['network']}.#{240 - i * 16}.0/20"
      end
      set!(e['network'], map)
    end
  end
end

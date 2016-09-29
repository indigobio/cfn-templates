SparkleFormation.dynamic(:dhcp_options_set) do |_name|

  # {
  #   "Type" : "AWS::EC2::DHCPOptions",
  #   "Properties" : {
  #     "DomainName" : String,
  #     "DomainNameServers" : [ String, ... ],
  #     "NetbiosNameServers" : [ String, ... ],
  #     "NetbiosNodeType" : Number,
  #     "NtpServers" : [ String, ... ],
  #     "Tags" : [ Resource Tag, ... ]
  #   }
  # }

  parameters(:search_domain) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default 'ec2.internal'
    description 'DNS search suffix'
    constraint_description 'can only contain ASCII characters'
  end

  resources("#{_name}_dhcp_options_set".gsub('-','_').to_sym) do
    type 'AWS::EC2::DHCPOptions'
    properties do
      domain_name ref!(:search_domain)
      domain_name_servers %w(AmazonProvidedDNS)
    end
  end

  # {
  #   "Type" : "AWS::EC2::VPCDHCPOptionsAssociation",
  #   "Properties" : {
  #     "DhcpOptionsId" : String,
  #     "VpcId" : String
  #   }
  # }

  resources("#{_name}_dhcp_options_association".gsub('-','_').to_sym) do
    type 'AWS::EC2::VPCDHCPOptionsAssociation'
    properties do
      dhcp_options_id ref!("#{_name}_dhcp_options_set".gsub('-','_').to_sym)
      vpc_id ref!(:vpc)
    end
  end
end
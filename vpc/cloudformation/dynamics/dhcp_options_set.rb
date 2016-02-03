SparkleFormation.dynamic(:dhcp_options_set) do |_name, _config = {}|

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

  resources("#{_name}_dhcp_options_set".to_sym) do
    type 'AWS::EC2::DHCPOptions'
  end
end
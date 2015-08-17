SparkleFormation.dynamic(:route53_hosted_domain) do |_name, _config = {}|

  # {
  #   "Type" : "AWS::Route53::HostedZone",
  #   "Properties" : {
  #     "HostedZoneConfig" : { HostedZoneConfig },
  #     "HostedZoneTags" : [  HostedZoneTags, ... ],
  #     "Name" : String,
  #     "VPCs" : [ HostedZoneVPCs, ... ]
  #   }
  # }

  _config[:domain_name] ||= "#{ENV['region']}.#{ENV['environment']}.#{ENV['org']}.internal"
  _config[:description] ||= 'A hosted route53 domain'

  parameters("#{_name.gsub('-','_')}_hosted_domain_name".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _config[:domain_name]
    description _config[:description]
    constraint_description 'can only contain ASCII characters'
  end

  resources("#{_name.gsub('-','_')}_hosted_domain".to_sym) do
    type 'AWS::Route53::HostedZone'
    properties do
      name _config[:domain_name]
      if _config.has_key?(:vpcs)
        v_p_cs _array(
          *_config[:vpcs].map { |vpc| -> {
            v_p_c_id vpc[:id]
            v_p_c_region vpc[:region]
          }
        })
      end
    end
  end
end
SparkleFormation.dynamic(:route53_hosted_zone) do |_name, _config = {}|

  # {
  #   "Type" : "AWS::Route53::HostedZone",
  #   "Properties" : {
  #     "HostedZoneConfig" : { HostedZoneConfig },
  #     "HostedZoneTags" : [  HostedZoneTags, ... ],
  #     "Name" : String,
  #     "VPCs" : [ HostedZoneVPCs, ... ]
  #   }
  # }

  _config[:zone_name] ||= ENV['private_domain']
  _config[:description] ||= 'A hosted route53 zone'

  parameters("#{_name.gsub('-','_')}_hosted_zone_name".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _config[:zone_name]
    description _config[:description]
    constraint_description 'can only contain ASCII characters'
  end

  resources("#{_name.gsub('-','_')}_hosted_zone".to_sym) do
    type 'AWS::Route53::HostedZone'
    properties do
      name _config[:zone_name]
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
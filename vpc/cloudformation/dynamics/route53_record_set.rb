SparkleFormation.dynamic(:route53_record_set) do |_name, _config = {}|

  ENV['org'] ||= 'indigo'
  ENV['environment'] ||= 'dr'
  ENV['region'] ||= 'us-east-1'

  # {
  #   "Type" : "AWS::Route53::RecordSet",
  #   "Properties" : {
  #     "AliasTarget" : AliasTarget,
  #     "Comment" : String,
  #     "Failover" : String,
  #     "GeoLocation" : { GeoLocation },
  #     "HealthCheckId" : String,
  #     "HostedZoneId" : String,
  #     "HostedZoneName" : String,
  #     "Name" : String,
  #     "Region" : String,
  #     "ResourceRecords" : [ String ],
  #     "SetIdentifier" : String,
  #     "TTL" : String,
  #     "Type" : String,
  #     "Weight" : Integer
  #   }
  # }

  _config[:domain_name]   ||= "#{ENV['region']}.#{ENV['environment']}.#{ENV['org']}.internal"
  _config[:type]        ||= 'CNAME'
  _config[:record]      ||= '*'
  _config[:attr]        ||= 'CanonicalHosteddomainName' # PublicIp for A records
  _config[:description] ||= "The DNS record to add to the #{_config[:domain_name]} domain"

  parameters("#{_name.gsub('-','_')}_domain_name".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _config[:domain_name]
    description 'A hosted route53 DNS domain'
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name.gsub('-','_')}_record".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default "#{_config[:record]}.#{_config[:domain_name]}."
    description _config[:description]
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name.gsub('-','_')}_record_type".to_sym) do
    type 'String'
    allowed_values %w(A AAAA CNAME MX NS PTR SOA SPF SRV TXT)
    description 'The DNS record type'
    default _config[:type]
  end

  parameters("#{_name.gsub('-','_')}_ttl".to_sym) do
    type 'Number'
    min_value '1'
    max_value '604800'
    description 'The maximum time to live for the DNS record'
    default _config.fetch(:ttl, '3600')
  end

  resources("#{_name.gsub('-','_')}_route53_record_set".to_sym) do
    type "AWS::Route53::RecordSet"
    properties do
      hosted_zone_name join!(ref!("#{_name.gsub('-','_')}_domain_name".to_sym), '.')
      name ref!("#{_name.gsub('-','_')}_record".to_sym)
      type ref!("#{_name.gsub('-','_')}_record_type".to_sym)
      resource_records _array(
        join!(attr!(_config[:target], _config[:attr]), ('.' unless _config[:attr].to_s =~ /ip/i))
      )
      set!('TTL', ref!("#{_name.gsub('-','_')}_ttl".to_sym))
    end
  end
end
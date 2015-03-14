SparkleFormation.dynamic(:route53_record_set) do |_name, _config = {}|

  ENV['org'] ||= 'indigo'
  ENV['environment'] ||= 'dr'
  ENV['region'] ||= 'us-east-1'
  pfx = "#{ENV['org']}-#{ENV['environment']}-#{ENV['region']}"

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

  _config[:zone_name] ||= "#{ENV['environment']}.#{ENV['org']}.internal"
  _config[:type] ||= 'CNAME'
  _config[:name] ||= '*'
  _config[:attr] ||= 'PublicIp'

  parameters("#{_name.gsub('-','_')}_zone_name".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _config[:zone_name]
    description 'An S3 bucket that contains the Chef validator private key.'
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name.gsub('-','_')}_record_name".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default "#{_config[:name]}.#{_config[:zone_name]}."
    description 'An S3 bucket that contains the Chef validator private key.'
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name.gsub('-','_')}_record_type".to_sym) do
    type 'String'
    allowed_values %w(A AAAA CNAME MX NS PTR SOA SPF SRV TXT)
    default _config[:type]
  end

  parameters("#{_name.gsub('-','_')}_ttl".to_sym) do
    type 'Number'
    min_value '1'
    max_value '604800'
    default _config.fetch(:ttl, '3600')
  end

  resources("#{_name.gsub('-','_')}_route53_record_set".to_sym) do
    type "AWS::Route53::RecordSet"
    properties do
      hosted_zone_name join!(ref!("#{_name.gsub('-','_')}_zone_name".to_sym), '.')
      name ref!("#{_name.gsub('-','_')}_record_name".to_sym)
      type ref!("#{_name.gsub('-','_')}_record_type".to_sym)
      resource_records _array(
        join!(attr!(_config[:target], _config[:attr]), ('.' unless _config[:attr].to_s =~ /ip/i))
      )
      set!('TTL', ref!("#{_name.gsub('-','_')}_ttl".to_sym))
    end
  end
end
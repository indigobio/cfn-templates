SparkleFormation.dynamic(:hosted_zone) do |_name, _config = {}|

  # {
  #   "Type" : "AWS::Route53::HostedZone",
  #   "Properties" : {
  #     "HostedZoneConfig" : { HostedZoneConfig },
  #     "Name" : String
  #   }
  # }

  resources("#{_name}_hosted_zone".to_sym) do
    type 'AWS::Route53::HostedZone'
    properties do
      hosted_zone_config do

      end
      name _name
    end
  end
end
SparkleFormation.dynamic(:cloudfront_distribution) do | _name, _config = {} |

# {
#   "Type" : "AWS::CloudFront::Distribution",
#     "Properties" : {
#     "DistributionConfig" : DistributionConfig
#   }
# }

# "DistributionConfig": {
#   "Aliases" : [ String, ... ],
#   "CacheBehaviors" : [ CacheBehavior, ... ],
#   "Comment" : String,
#   "CustomErrorResponses" : [ CustomErrorResponse, ... ],
#   "DefaultCacheBehavior" : DefaultCacheBehavior,
#   "DefaultRootObject" : String,
#   "Enabled" : Boolean,
#   "Logging" : Logging,
#   "Origins" : [ Origin, ... ],
#   "PriceClass" : String,
#   "Restrictions" : Restriction,
#   "ViewerCertificate" : ViewerCertificate,
#   "WebACLId" : String
# }

# "DefaultCacheBehavior": {
#   "AllowedMethods" : [ String, ... ],
#   "CachedMethods" : [ String, ... ],
#   "DefaultTTL" : Number,
#   "ForwardedValues" : ForwardedValues,
#   "MaxTTL" : Number,
#   "MinTTL" : Number,
#   "SmoothStreaming" : Boolean,
#   "TargetOriginId" : String,
#   "TrustedSigners" : [ String, ... ],
#   "ViewerProtocolPolicy" : String
# }

# "ForwardedValues": {
#   "Cookies" : Cookies,
#   "Headers" : [ String, ... ],
#   "QueryString" : Boolean
# }

# "Origins": {
#   "CustomOriginConfig" : Custom Origin,
#   "DomainName" : String,
#   "Id" : String,
#   "OriginPath" : String,
#   "S3OriginConfig" : S3 Origin
# }

# Eff.
#  "CustomOriginConfig": {
#    "HTTPPort" : String,
#    "HTTPSPort" : String,
#    "OriginProtocolPolicy" : String
#  }

# Eww.
# "S3OriginConfig" : {
#   "OriginAccessIdentity" : "origin-access-identity/cloudfront/E127EXAMPLE51Z"
# }

  _config[:price_class] ||= 'PriceClass_100'

  parameters("#{_name}_price_class".to_sym) do
    type 'String'
    allowed_values %w(PriceClass_100 PriceClass_200 PriceClass_All)
    default _config[:price_class]
    description 'https://aws.amazon.com/cloudfront/pricing/'
  end

  parameters("#{_name}_comment".to_sym) do
    type 'String'
    default ENV['public_domain']
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Comment to assign to CloudFront distribution, used in search by Chef'
    constraint_description 'can only contain ASCII characters'
  end

  resources("#{_name}_cloudfront_distribution".to_sym) do
    type 'AWS::CloudFront::Distribution'
    properties do
      distribution_config do
        enabled 'true'
        comment ref!("#{_name}_comment".to_sym)
        default_cache_behavior do
          forwarded_values do
            cookies do
              forward 'all'
            end
            query_string 'true'
          end
          target_origin_id _name
          viewer_protocol_policy 'redirect-to-https'
        end
        origins _array(
          -> {
            if _config.has_key?(:bucket)
              s3_origin_config registry!(:empty_s3_origin_config)
              domain_name attr!(_config[:bucket], :domain_name)
            else
              custom_origin_config do
                h_t_t_p_port '80'
                h_t_t_p_s_port '443'
                origin_protocol_policy 'match-viewer'
              end
              domain_name _config.fetch(:origin, '{}')
            end
            id _name
          }
        )
        price_class 'PriceClass_100'
      end
    end
  end

  outputs do
    domain_name do
      value attr!("#{_name}_cloudfront_distribution".to_sym, :domain_name)
    end
    id do
      value ref!("#{_name}_cloudfront_distribution".to_sym)
    end
  end
end
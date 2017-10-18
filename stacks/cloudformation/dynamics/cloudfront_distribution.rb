SparkleFormation.dynamic(:cloudfront_distribution) do | _name, _config = {} |

# http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-cloudfront-distribution.html

  _config[:price_class] ||= 'PriceClass_100'
  _config[:ssl_certificate_id] ||= 'default'

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

  parameters("#{_name}_aliases".to_sym) do
    type 'CommaDelimitedList'
    default "assets.#{ENV['public_domain']}"
    description 'Custom domain name for CloudFront distribution'
  end

  parameters("#{_name}_ssl_certificate_id".to_sym) do
    type 'String'
    default _config[:ssl_certificate_id]
    description 'SSL certificate ARN to use with the cloudfront distribution'
  end

  parameters("#{_name}_ssl_certificate_type".to_sym) do
    type 'String'
    allowed_values %w(acm iam default)
    default 'default'
    description 'Type of SSL certificate to use with cloudfront. Default uses the *.cloudfront.net wildcard cert.'
  end

  conditions.set!(
    "#{_name}_uses_default_cert".to_sym,
    equals!(ref!("#{_name}_ssl_certificate_id".to_sym), 'default')
  )

  conditions.set!(
    "#{_name}_uses_iam_cert".to_sym,
    equals!(ref!("#{_name}_ssl_certificate_type".to_sym), 'iam')
  )

  conditions.set!(
    "#{_name}_uses_acm_cert".to_sym,
    equals!(ref!("#{_name}_ssl_certificate_type".to_sym), 'acm')
  )


  resources("#{_name}_cloudfront_distribution".to_sym) do
    type 'AWS::CloudFront::Distribution'
    properties do
      distribution_config do
        enabled 'true'
        aliases ref!("#{_name}_aliases".to_sym)
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
        viewer_certificate do
          acm_certificate_arn if!("#{_name}_uses_acm_cert".to_sym, ref!("#{_name}_ssl_certificate_id".to_sym), no_value!)
          iam_certificate_id if!("#{_name}_uses_iam_cert".to_sym, ref!("#{_name}_ssl_certificate_id".to_sym), no_value!)
          cloud_front_default_certificate if!("#{_name}_uses_default_cert".to_sym, 'true', no_value!)
          ssl_support_method 'sni-only'
        end
        origins _array(
          -> {
            if _config.has_key?(:bucket)
              data![:S3OriginConfig] = {}
              domain_name attr!(_config[:bucket], :domain_name)
            else
              custom_origin_config do
                data![:HTTPPort] = '80'
                data![:HTTPSPort] = '443'
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

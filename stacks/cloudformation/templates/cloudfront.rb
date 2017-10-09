require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

SparkleFormation.new('cloudfront').load(:git_rev_outputs).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates a Cloudfront distribution and an S3 bucket to hold public assets.
EOF

  dynamic!(:cloudfront_distribution, 'assets', :origin => "static.#{ENV['public_domain']}")

  dynamic!(:route53_record_set, 'assets',
           :type =>  'CNAME',
           :record => 'assets',
           :target => :assets_cloudfront_distribution,
           :domain_name => ENV['public_domain'],
           :attr => 'DomainName',
           :ttl => '60'
           )
end

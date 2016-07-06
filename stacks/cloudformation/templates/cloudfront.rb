require 'sparkle_formation'
require_relative '../../../utils/environment'
require_relative '../../../utils/lookup'

SparkleFormation.new('cloudfront').overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates a Cloudfront distribution and an S3 bucket to hold public assets.
EOF

  dynamic!(:cloudfront_distribution, 'assets', :origin => "static.#{ENV['public_domain']}")
end

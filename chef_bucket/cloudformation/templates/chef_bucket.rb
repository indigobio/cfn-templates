require 'sparkle_formation'

ENV['org'] ||= 'indigo'
ENV['region'] ||= 'us-east-1'

SparkleFormation.new('chef_bucket').load(:chef_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
This template creates an S3 bucket and a bucket policy that allows all users in your
AWS account to read objects from the bucket.  You will need to upload your Chef
validator client keys and encrypted data bag secrets into this bucket.  Optionally,
you could also use this bucket to hold cookbook bundles for Berkshelf, if you're
into that sort of thing.  I don't use Berkshelf (yet) so YMMV.

All other stacks will create an IAM instance role and IAM instance profile that has,
at bare minimum, s3::GetObject and s3::ListObject access to this bucket.
EOF
end

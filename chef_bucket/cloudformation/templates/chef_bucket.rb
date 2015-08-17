require 'sparkle_formation'
require_relative('../../../utils/environment')

SparkleFormation.new('chef_bucket').load(:chef_bucket).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an S3 bucket and a bucket policy that allows all users in your AWS account to read objects
from the bucket.  You will need to upload your Chef validator client keys and encrypted data bag
secrets into this bucket.

All other stacks will create an IAM instance role and IAM instance profile that has, at bare minimum,
s3::GetObject and s3::ListObject access to this bucket.
EOF
end

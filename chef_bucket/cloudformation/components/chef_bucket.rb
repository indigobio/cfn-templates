SparkleFormation.build do

  set!('AWSTemplateFormatVersion', '2010-09-09')

  parameters(:bucket_name) do
    type 'String'
    allowed_pattern "[-.a-z0-9]*"
    default "#{ENV['org']}-chef-#{ENV['region']}"
    description 'An S3 bucket that contains the Chef validator private key.'
    constraint_description 'may only contain lower case letters, numbers, periods and dashes'
  end

  resources(:chef_validator_key_bucket) do
    type 'AWS::S3::Bucket'
    properties do
      access_control 'Private'
      bucket_name ref!(:bucket_name)
      tags _array(
        -> {
          key 'Name'
          value ref!(:bucket_name)
        }
      )
    end
  end

  resources(:chef_validator_key_bucket_policy) do
    type 'AWS::S3::BucketPolicy'
    properties do
      bucket ref!(:chef_validator_key_bucket)
      policy_document do
        version '2008-10-17'
        id 'ReadPolicy'
        statement _array(
          -> {
            sid 'ReadAccess'
            action %w(s3:GetObject)
            effect 'Allow'
            resource join!(
              "arn:aws:s3:::",
              ref!(:chef_validator_key_bucket),
              "/*"
            )
            principal do
              a_w_s join!(
                'arn:aws:iam::',
                ref!('AWS::AccountId'),
                ':root'
              )
            end
          }
        )
      end
    end
  end

  outputs do
    bucket_name do
      value attr!(:chef_validator_key_bucket, 'DomainName')
      description "Chef Validator Key Bucket Domain Name"
    end
  end
end
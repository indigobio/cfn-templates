SparkleFormation.dynamic(:s3_bucket) do |_name, _config = {}|

  parameters("#{_name}_bucket_name".gsub('-', '_').to_sym) do
    type 'String'
    allowed_pattern "[-.a-z0-9]*"
    default "#{ENV['org']}-#{ENV['environment']}-#{_name}-#{ENV['AWS_DEFAULT_REGION']}"
    description 'An S3 bucket that contains the AWS Lambda function.'
    constraint_description 'may only contain lower case letters, numbers, periods and dashes'
  end

  resources("#{_name}_s3_bucket".gsub('-', '_').to_sym) do
    type 'AWS::S3::Bucket'
    properties do
      access_control 'Private'
      bucket_name ref!("#{_name}_bucket_name".gsub('-', '_').to_sym)
      tags _array(
        -> {
          key 'Name'
          value ref!("#{_name}_bucket_name".gsub('-', '_').to_sym)
        }
      )
    end
  end
end

SparkleFormation.build do

  parameters(:bucket_name) do
    type 'String'
    allowed_pattern "[-.a-z0-9]*"
    default "#{ENV['org']}-chef-#{ENV['AWS_DEFAULT_REGION']}"
    description 'An S3 bucket that contains the AWS Lambda function.'
    constraint_description 'may only contain lower case letters, numbers, periods and dashes'
  end

  resources(:lambda_bucket) do
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
end

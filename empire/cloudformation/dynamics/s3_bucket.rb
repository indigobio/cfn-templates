SparkleFormation.dynamic(:s3_bucket) do |_name, _config = {}|

  # A very basic S3 bucket, intended for use with CloudFront in a pinch.

  # {
  #   "Type" : "AWS::S3::Bucket",
  #   "Properties" : {
  #     "AccessControl" : String,
  #     "BucketName" : String,
  #     "CorsConfiguration" : CORS Configuration,
  #     "LifecycleConfiguration" : Lifecycle Configuration,
  #     "LoggingConfiguration" : Logging Configuration,
  #     "NotificationConfiguration" : Notification Configuration,
  #     "ReplicationConfiguration" : Replication Configuration,
  #     "VersioningConfiguration" : Versioning Configuration,
  #     "WebsiteConfiguration" : Website Configuration Type
  #   }
  # }

  # If you specify a BucketName, you cannot do updates that require this resource to be replaced.
  # You can still do updates that require no or some interruption.
  # If you must replace the resource, specify a new name.

  parameters("#{_name}_acl".to_sym) do
    type "String"
    allowed_values %w(AuthenticatedRead
                      AwsExecRead
                      BucketOwnerRead
                      BucketOwnerFullControl
                      LogDeliveryWrite
                      Private
                      PublicRead
                      PublicReadWrite)
    default _config.fetch(:acl, 'Private')
    description 'Canned ACL to apply to the bucket.  http://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl'
  end

  resources("#{_name}_s3_bucket".to_sym) do
    type 'AWS::S3::Bucket'
    properties do
      access_control ref!("#{_name}_acl".to_sym)
      if _config.has_key?(:bucket_name)
        bucket_name _config[:bucket_name]
      end

      tags _array(
        -> {
          key 'Environment'
          value ENV['environment']
        },
        -> {
          key 'Purpose'
          value _config.fetch(:purpose, _name)
        }
      )
    end
  end
end
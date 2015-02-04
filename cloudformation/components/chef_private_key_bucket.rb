SparkleFormation.build do
  set!('AWSTemplateFormatVersion', '2010-09-09')

  resources.bucket_policy do
    type 'AWS::S3::BucketPolicy'
    properties.policy_document.version '2008-10-17'
    properties.policy_document.id 'ReadPolicy'
    properties.policy_document.statement _array(
      -> {
        sid 'ReadAccess'
        action [ 's3::GetObject' ]
        effect 'Allow'
        resource Ref!
      }
                                         )
  end
end
SparkleFormation.dynamic(:s3_owner_write_bucket_policy) do |_name, _config = {}|

  # {
  #   "Type" : "AWS::S3::BucketPolicy",
  #   "Properties" : {
  #     "Bucket" : String,
  #     "PolicyDocument" : JSON
  #   }
  # }

  resources("#{_name}_s3_bucket_policy".to_sym) do
    type 'AWS::S3::BucketPolicy'
    properties do
      bucket ref!(_config[:bucket])
      policy_document do
        version '2008-10-17'
        id "#{_name}SyncPolicy"
        statement _array(
          -> {
            sid "#{_name}SyncBucketAccess"
            action %w(s3:*)
            effect 'Allow'
            resource join!(
              'arn:aws:s3:::',
              ref!(_config[:bucket])
            )
            principal do
              a_w_s join!(
                'arn:aws:iam::',
                ref!('AWS::AccountId'),
                ':root'
              )
            end
          },
          -> {
            sid "#{_name}SyncObjectsAccess"
            action %w(s3:*)
            effect 'Allow'
            resource join!(
              'arn:aws:s3:::',
              ref!(_config[:bucket]),
              '/*'
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
end
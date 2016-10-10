SparkleFormation.dynamic(:lambda_function) do |_name, _config = {}|

  # {
  #   "Type" : "AWS::Lambda::Function",
  #   "Properties" : {
  #     "Code" : Code,
  #     "Description" : String,
  #     "Handler" : String,
  #     "MemorySize" : Integer,
  #     "Role" : String,
  #     "Runtime" : String,
  #     "Timeout" : Integer,
  #     "VpcConfig" : VPCConfig
  #   }
  # }

  # {
  #   "SecurityGroupIds" : [ String, ... ],
  #   "SubnetIds" : [ String, ... ]
  # }

  parameters("#{_name}_code_key".gsub('-', '_').to_sym) do
    type 'String'
    default _config.fetch(:key, "#{_name}/#{_name}.zip")
    allowed_pattern "[\\x20-\\x7E]*"
    description 'S3 key (path) of the zip file containing the deployment package'
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_timeout".gsub('-', '_').to_sym) do
    type 'Number'
    min_value 5
    default _config.fetch(:timeout, 120)
    description 'Timeout (in seconds) for the lambda function'
  end

  parameters("#{_name}_memory_size".gsub('-', '_').to_sym) do
    type 'Number'
    min_value 128
    default _config.fetch(:memory_size, 128)
    description 'Memory (in MB) for the lambda function'
  end

  parameters("#{_name}_description".gsub('-', '_').to_sym) do
    type 'String'
    default _name
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Lambda description'
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_handler".gsub('-', '_').to_sym) do
    type 'String'
    default "#{ _config.fetch(:handler, _name) }.lambda_handler"
    allowed_pattern "[\\x20-\\x7E]*"
    description 'Lambda handler function name'
    constraint_description 'can only contain ASCII characters'
  end

  resources("#{_name}_lambda_function".gsub('-', '_').to_sym) do
    type 'AWS::Lambda::Function'
    properties do
      code do
        s3_bucket _config[:bucket]
        s3_key ref!("#{_name}_code_key".gsub('-', '_').to_sym)
      end
      description ref!("#{_name}_description".gsub('-', '_').to_sym)
      handler ref!("#{_name}_handler".gsub('-', '_').to_sym)
      memory_size ref!("#{_name}_memory_size".gsub('-', '_').to_sym)
      role attr!(_config[:role], :arn)
      runtime 'python2.7'
      timeout ref!("#{_name}_timeout".gsub('-', '_').to_sym)
      vpc_config do
        security_group_ids _config[:security_groups]
        subnet_ids _config[:subnet_ids]
      end
    end
  end
end

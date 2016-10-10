SparkleFormation.dynamic(:sns_topic) do |_name, _config = {}|

  conditions.set!(
      :sns_topic_has_name,
      not!(equals!(ref!(:sns_topic_name), 'none'))
  )

  parameters(:sns_topic_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    description 'The name of the termination SNS topic'
    constraint_description 'can only contain ASCII characters'
    default _name
  end

  resources("#{_name}_sns_topic".gsub('-', '_').to_sym) do
    type 'AWS::SNS::Topic'
    properties do
      topic_name if!(:sns_topic_has_name, ref!(:sns_topic_name), no_value!)
      subscription _array(
        -> {
          endpoint attr!(_config[:subscriber], :arn)
          protocol 'lambda'
        }
      )
    end
  end

  outputs("#{_name}_sns_topic".gsub('-', '_').to_sym) do
    description "SNS Topic ARN for RDS DB Instance Creations"
    value ref!("#{_name}_sns_topic".gsub('-', '_').to_sym)
  end
end

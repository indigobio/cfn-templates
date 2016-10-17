SparkleFormation.dynamic(:iam_policy) do |_name, _config = {}|

  resources("#{_name}_iam_policy".gsub('-', '_').to_sym) do
    type 'AWS::IAM::Policy'
    depends_on "#{_name}IamRole"
    properties do
      policy_name _name
      policy_document do
        version '2012-10-17'
        statement _array(
          { 'Action' => %w(logs:CreateLogGroup
                           logs:CreateLogStream
                           logs:PutLogEvents
                        ),
            'Resource' => 'arn:aws:logs:*:*:*',
            'Effect' => 'Allow'
          },
          *_config.fetch(:policy_statements, []).map { |s| s.is_a?(Hash) ? registry!(s.keys.first.to_sym, s.values.first) : registry!(s.to_sym) },
        )
      end
      roles _array( ref!("#{_name}_iam_role".gsub('-', '_').to_sym) )
    end
  end
end

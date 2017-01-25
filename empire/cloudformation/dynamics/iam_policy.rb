SparkleFormation.dynamic(:iam_policy) do |_name, _config = {}|

  _config[:policy_statements] ||= []
  statements = Array.new

  if _config[:policy_statements].is_a?(Array)
    statements = _config[:policy_statements].map { |statements| registry!(statements.to_sym) }.first
  elsif _config[:policy_statements].is_a?(Hash)
    statements = _config[:policy_statements].map { |statements, config| registry!(statements.to_sym, config) }.first
  end

  resources("#{_name}_iam_policy".to_sym) do
    type 'AWS::IAM::Policy'
    depends_on _config.fetch(:roles, [ "#{_name.capitalize}IamRole" ])
    properties do
      policy_name _name
      policy_document do
        version '2012-10-17'
        statement statements
      end
      roles _config.fetch(:roles, [ "#{_name.capitalize}IamRole" ]).map { |r| ref!(r) }
    end
  end
end

